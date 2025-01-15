import {CanActivateFn, Router} from '@angular/router';
import {inject} from "@angular/core";
import {UserinfoService} from "../services/userinfo.service";

export const isLoggedInGuard: CanActivateFn = (route, state) => {
  const router = inject(Router);
  const serv = inject(UserinfoService);

  if (!serv.isLogged) {
    router.navigateByUrl('login');
    return false;
  }
  return true;
};
