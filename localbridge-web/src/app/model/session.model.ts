export interface SessionCreateRequest {
  deviceId: string;
  deviceName: string;
}

export interface SessionCreateResponse {
  sessionId: string;
  [key: string]: unknown;
}

export type SessionId = string;
