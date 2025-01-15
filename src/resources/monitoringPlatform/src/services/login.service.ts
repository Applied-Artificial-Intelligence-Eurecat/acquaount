import {Injectable} from '@angular/core';
import {HttpClient} from "@angular/common/http";
import {environment} from "../environments/environment";


@Injectable({
  providedIn: 'root'
})
export class LoginService {

  constructor(public httpClient: HttpClient) {

  }

  url(addr: string) {
    return environment.loginUrl + addr;
  }

  loginUser(username: string, password: string) {
    return this.httpClient.post<any>(this.url('/login'), {
      "username": username,
      "password": password
    });
  }

  registerUser(username: string, password: string) {
    return this.httpClient.post<any>(this.url('/register'), {
      "username": username,
      "password": password
    });
  }
}
