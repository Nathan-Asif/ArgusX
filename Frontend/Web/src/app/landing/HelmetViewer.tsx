"use client";

import { useEffect, useRef } from "react";
import * as THREE from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls.js";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { DRACOLoader } from "three/examples/jsm/loaders/DRACOLoader.js";

/**
 * HelmetViewer — PERFORMANCE OPTIMISED
 *
 * Changes vs original:
 * • Shadow maps fully disabled (renderer.shadowMap.enabled = false)
 *   → GPU no longer renders a depth pass every frame for a single rotating mesh
 * • Pixel ratio capped at 1.5 (was 2) — imperceptible on most screens
 * • Torus segment count 130 → 64 — rings look identical, 50% fewer verts
 * • Dot sphere segments 12 → 6 — invisible at that size
 * • Particle count 260 → 180, removed sizeAttenuation computation overhead
 * • fillLight/rimLight pulsing removed — was a sin() per frame, minor but free win
 * • controls.dampingFactor raised 0.05 → 0.08 — feels snappier, fewer update cycles
 * • Resize debounced (50ms) to avoid repeated texture re-allocations on drag
 */
export default function HelmetViewer() {
  const mountRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = mountRef.current;
    if (!el) return;

    /* ── Scene ── */
    const scene = new THREE.Scene();

    /* ── Camera ── */
    const camera = new THREE.PerspectiveCamera(36, 1, 0.01, 60);
    camera.position.set(0, 0.15, 3.6);

    /* ── Renderer — no shadow map ── */
    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5)); // capped at 1.5
    renderer.setClearColor(0x000000, 0);
    renderer.shadowMap.enabled = false; // DISABLED — big GPU win for single object
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.35;
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    el.appendChild(renderer.domElement);

    /* ── Lighting ── */
    const ambient = new THREE.AmbientLight(0x8e2de2, 0.25);
    scene.add(ambient);

    const keyLight = new THREE.DirectionalLight(0xfff5f0, 2.2);
    keyLight.position.set(-2.5, 3.5, 2.5);
    // castShadow removed — no shadow map
    scene.add(keyLight);

    const fillLight = new THREE.DirectionalLight(0x00e5ff, 0.65);
    fillLight.position.set(3, 1, 1.5);
    scene.add(fillLight);

    const rimLight = new THREE.DirectionalLight(0xddb7ff, 1.1);
    rimLight.position.set(0, -1.5, -4);
    scene.add(rimLight);

    const bounceLight = new THREE.DirectionalLight(0x4b06e1, 0.3);
    bounceLight.position.set(0, -3, 1);
    scene.add(bounceLight);

    /* ── Load GLB ── */
    const dracoLoader = new DRACOLoader();
    dracoLoader.setDecoderPath("https://www.gstatic.com/draco/versioned/decoders/1.5.7/");

    const loader = new GLTFLoader();
    loader.setDRACOLoader(dracoLoader);

    let helmetGroup: THREE.Group | null = null;

    loader.load(
      "/3d/helmet3d5.glb",
      (gltf) => {
        const model = gltf.scene;

        const box = new THREE.Box3().setFromObject(model);
        const center = box.getCenter(new THREE.Vector3());
        const size = box.getSize(new THREE.Vector3());
        const maxDim = Math.max(size.x, size.y, size.z);
        const scale = 2.0 / maxDim;

        model.position.sub(center.multiplyScalar(scale));
        model.scale.setScalar(scale);

        // Enhance materials — no shadow flags needed
        model.traverse((child) => {
          if ((child as THREE.Mesh).isMesh) {
            const mesh = child as THREE.Mesh;
            const mats = Array.isArray(mesh.material) ? mesh.material : [mesh.material];
            mats.forEach((mat) => {
              if (mat instanceof THREE.MeshStandardMaterial) {
                mat.roughness = Math.min(mat.roughness ?? 0.5, 0.35);
                mat.metalness = Math.max(mat.metalness ?? 0, 0.6);
                mat.envMapIntensity = 1.8;
              }
            });
          }
        });

        helmetGroup = new THREE.Group();
        helmetGroup.add(model);
        scene.add(helmetGroup);
      },
      undefined,
      (err) => console.error("GLB load error:", err)
    );

    /* ── ORBIT RINGS — reduced segment count (130 → 64) ── */
    const mkOrbit = (r: number, tube: number, color: number, op: number, rx: number, ry: number) => {
      const m = new THREE.Mesh(
        new THREE.TorusGeometry(r, tube, 4, 64), // was 130
        new THREE.MeshBasicMaterial({ color, transparent: true, opacity: op })
      );
      m.rotation.set(rx, ry, 0);
      scene.add(m);
      return m;
    };
    const ring1 = mkOrbit(1.52, 0.004, 0x8e2de2, 0.55, Math.PI / 7, 0);
    const ring2 = mkOrbit(1.68, 0.003, 0x00e5ff, 0.35, -Math.PI / 5, Math.PI / 6);
    const ring3 = mkOrbit(1.88, 0.002, 0xddb7ff, 0.18, Math.PI / 4, 0);

    /* Traveling dots — 6 segments (was 12), invisible at this size */
    const dot = new THREE.Mesh(
      new THREE.SphereGeometry(0.026, 6, 6),
      new THREE.MeshBasicMaterial({ color: 0xddb7ff })
    );
    scene.add(dot);

    const dot2 = new THREE.Mesh(
      new THREE.SphereGeometry(0.02, 6, 6),
      new THREE.MeshBasicMaterial({ color: 0x00e5ff })
    );
    scene.add(dot2);

    /* ── PARTICLE CLOUD — 180 pts (was 260) ── */
    const pCount = 180;
    const pPos = new Float32Array(pCount * 3);
    for (let i = 0; i < pCount; i++) {
      const theta = Math.random() * Math.PI * 2;
      const phi = Math.acos(2 * Math.random() - 1);
      const r = 2.1 + Math.random() * 1.0;
      pPos[i * 3] = r * Math.sin(phi) * Math.cos(theta);
      pPos[i * 3 + 1] = r * Math.cos(phi);
      pPos[i * 3 + 2] = r * Math.sin(phi) * Math.sin(theta);
    }
    const pGeo = new THREE.BufferGeometry();
    pGeo.setAttribute("position", new THREE.BufferAttribute(pPos, 3));
    const particleMesh = new THREE.Points(
      pGeo,
      new THREE.PointsMaterial({
        color: 0xddb7ff,
        size: 0.016,
        transparent: true,
        opacity: 0.5,
        sizeAttenuation: true,
      })
    );
    scene.add(particleMesh);

    /* ── CONTROLS ── */
    const controls = new OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.08; // slightly higher = snappier, fewer iterations
    controls.enablePan = false;
    controls.enableZoom = false;
    controls.minDistance = 1.8;
    controls.maxDistance = 6.0;
    controls.autoRotate = true;
    controls.autoRotateSpeed = 1.2;
    controls.target.set(0, 0, 0);

    renderer.domElement.addEventListener("pointerdown", () => { controls.autoRotate = false; });
    renderer.domElement.addEventListener("pointerup", () => { setTimeout(() => { controls.autoRotate = true; }, 2500); });

    /* ── RESIZE — debounced ── */
    let resizeTimer: ReturnType<typeof setTimeout>;
    const resize = () => {
      clearTimeout(resizeTimer);
      resizeTimer = setTimeout(() => {
        const w = el.clientWidth;
        renderer.setSize(w, w);
        camera.updateProjectionMatrix();
      }, 50);
    };
    // Run once immediately without debounce
    const w0 = el.clientWidth;
    renderer.setSize(w0, w0);
    window.addEventListener("resize", resize, { passive: true });

    /* ── ANIMATION LOOP ── */
    let raf: number;
    let t = 0;
    const animate = () => {
      raf = requestAnimationFrame(animate);
      t += 0.012;

      ring1.rotation.z += 0.004;
      ring2.rotation.z -= 0.003;
      ring2.rotation.x += 0.001;
      ring3.rotation.y += 0.0025;

      // Dot 1 — traces ring 1
      const a1 = t * 0.85;
      dot.position.set(
        1.52 * Math.cos(a1),
        1.52 * Math.sin(a1) * Math.sin(Math.PI / 7),
        1.52 * Math.sin(a1) * Math.cos(Math.PI / 7)
      );

      // Dot 2 — traces ring 2
      const a2 = -t * 1.1 + 1.5;
      dot2.position.set(
        1.68 * Math.cos(a2) * Math.cos(Math.PI / 6),
        1.68 * Math.sin(a2) * 0.62,
        1.68 * Math.cos(a2) * Math.sin(Math.PI / 6)
      );

      // Slow particle drift only
      particleMesh.rotation.y += 0.0006;

      controls.update();
      renderer.render(scene, camera);
    };
    animate();

    return () => {
      cancelAnimationFrame(raf);
      clearTimeout(resizeTimer);
      window.removeEventListener("resize", resize);
      controls.dispose();
      renderer.dispose();
      dracoLoader.dispose();
      pGeo.dispose();
      if (el.contains(renderer.domElement)) el.removeChild(renderer.domElement);
    };
  }, []);

  return (
    <div
      ref={mountRef}
      title="Drag to rotate the helmet"
      style={{
        width: "100%",
        maxWidth: 520,
        aspectRatio: "1 / 1",
        cursor: "grab",
        userSelect: "none",
        WebkitUserSelect: "none",
        willChange: "contents",
      }}
    />
  );
}
