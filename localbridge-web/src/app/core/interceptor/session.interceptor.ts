import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, throwError } from 'rxjs';
import { SessionService } from '../services/session.service';

/**
 * HTTP Interceptor function that:
 * 1. Adds X-Session-Id header to all requests
 * 2. Handles 401 Unauthorized responses (session expired)
 */
export const sessionInterceptor: HttpInterceptorFn = (req, next) => {
  const sessionService = inject(SessionService);

  const isExternalPhoneRequest =
    /^https?:\/\//i.test(req.url) &&
    !req.url.startsWith(window.location.origin);

  // Add session ID header only for same-origin app requests.
  // Phone-server endpoints authenticate using the token query param and
  // cross-origin preflight requests must not carry the app session header.
  const sessionId = sessionService.getSessionId();
  if (sessionId && !isExternalPhoneRequest) {
    req = req.clone({
      setHeaders: {
        'X-Session-Id': sessionId,
      },
    });
  }

  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401) {
        // Session expired or invalid
        console.error('[sessionInterceptor] Session expired - received 401');
        sessionService.clearSessionId();
        // Optionally redirect to login or show reconnection prompt
      }
      return throwError(() => error);
    })
  );
};
