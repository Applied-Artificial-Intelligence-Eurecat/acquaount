import {Component} from '@angular/core';
import {ButtonModule} from "primeng/button";
import {InputTextModule} from "primeng/inputtext";
import {PasswordModule} from "primeng/password";
import {FormsModule, ReactiveFormsModule} from "@angular/forms";
import {Router} from "@angular/router";
import {NgClass, NgIf} from "@angular/common";
import {CalendarModule} from "primeng/calendar";
import {DropdownModule} from "primeng/dropdown";
import {BadgeModule} from "primeng/badge";
import {LoginService} from "../../services/login.service";

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [
    ButtonModule,
    InputTextModule,
    PasswordModule,
    ReactiveFormsModule,
    FormsModule,
    NgClass,
    CalendarModule,
    DropdownModule,
    BadgeModule,
    NgIf
  ],
  templateUrl: './register.component.html',
  styleUrl: './register.component.scss'
})
export class RegisterComponent {
  dob: Date | undefined;

  username: string = "";
  password: string = "";
  confirmPassword: string = "";

  isValid: boolean = true;

  registerError: boolean = false;

  constructor(private router: Router,
              private loginService: LoginService) {
  }

  submit() {
    if (this.password !== this.confirmPassword) {
      console.log("Passwords do not match");
      return;
    }

    this.loginService.registerUser(this.username, this.password).subscribe(r => {
      this.goToLogin();
    }, error => {
      this.registerError = true;
    });
  }

  goToLogin() {
    this.router.navigateByUrl('login');
  }
}
