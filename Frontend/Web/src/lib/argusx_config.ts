/** Production defaults — override in `.env.local` for local dev. */
export const ARGUSX_API_URL =
  process.env.NEXT_PUBLIC_ARGUSX_API_URL ??
  "https://argusx-api.codemelodies.com";

export const ARGUSX_WS_PULSE_URL =
  process.env.NEXT_PUBLIC_ARGUSX_WS_URL ??
  "wss://argusx-api.codemelodies.com/ws/pulse";
