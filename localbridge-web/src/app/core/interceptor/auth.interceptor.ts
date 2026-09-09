import { HttpInterceptorFn } from '@angular/common/http';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const token = localStorage.getItem('localbridge_token') || '';

  const clonedReq = req.clone({
    setHeaders: { 'X-LocalBridge-Token': token },
  });

  return next(clonedReq);
};
