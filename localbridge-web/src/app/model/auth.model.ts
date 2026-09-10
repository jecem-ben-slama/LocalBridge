export interface AuthVerifyRequest {
  token: string;
}

export interface AuthVerifyResponse {
  [key: string]: unknown;
}

/** Query-string keys a pairing token may arrive under (QR code / pairing link). */
export const PAIRING_TOKEN_PARAMS = ['token', 'pairing_token', 'pairing_code', 'code'] as const;
