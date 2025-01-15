import {Component, OnInit} from '@angular/core';
import {CalendarModule} from "primeng/calendar";
import {FormsModule} from "@angular/forms";
import {provideAnimations} from "@angular/platform-browser/animations";
import {InputTextModule} from "primeng/inputtext";
import {PasswordModule} from "primeng/password";
import {NgClass, NgIf} from "@angular/common";
import {Router} from "@angular/router";
import {ToggleButtonModule} from "primeng/togglebutton";
import {LoginService} from "../../services/login.service";
import {UserinfoService} from "../../services/userinfo.service";

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [
    CalendarModule,
    FormsModule,
    InputTextModule,
    PasswordModule,
    NgIf,
    NgClass,
    ToggleButtonModule
  ],
  providers: [
    provideAnimations()
  ],
  templateUrl: './login.component.html',
  styleUrl: './login.component.scss'
})
export class LoginComponent implements OnInit {
  username: string | undefined;
  password: string | undefined;

  isValid: boolean = true;

  loginError: boolean = false;

  constructor(private router: Router,
              private loginService: LoginService,
              private userinfo: UserinfoService) {
  }

  ngOnInit() {
  }

  login() {
    if (this.username !== undefined && this.password !== undefined) {
      this.loginService.loginUser(this.username, this.password).subscribe(r => {
        this.userinfo.isLogged = true;
        this.router.navigateByUrl('');
      }, error => {
        this.loginError = true;
      });
    }
  }

  goToRegister() {
    this.router.navigateByUrl('register');
  }
}
