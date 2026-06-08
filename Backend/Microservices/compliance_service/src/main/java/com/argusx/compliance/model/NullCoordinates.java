package com.argusx.compliance.model;

/**
 * Lab 8 — Null Object: safe fallback when coordinates are missing or corrupt.
 * Prevents null-pointer failures in downstream report assembly.
 */
public class NullCoordinates implements Coordinates {

    public static final NullCoordinates INSTANCE = new NullCoordinates();

    private NullCoordinates() {}

    @Override
    public boolean isNull() {
        return true;
    }

    @Override
    public double getLat() {
        return 0.0;
    }

    @Override
    public double getLng() {
        return 0.0;
    }

    @Override
    public String describe() {
        return "NULL_COORDINATES — no spatial grounding applied";
    }
}
