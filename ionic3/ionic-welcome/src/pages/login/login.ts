import { Component } from '@angular/core';
import { IonicPage, NavController, NavParams } from 'ionic-angular';
import { TabsPage } from '../tabs/tabs';
import { Platform } from 'ionic-angular';

/**
 * Generated class for the Login page.
 *
 * See http://ionicframework.com/docs/components/#navigation for more info
 * on Ionic pages and navigation.
 */
@IonicPage()
@Component({
  selector: 'page-login',
  templateUrl: 'login.html',
})

export class Login {

  userId:string = '';
  password:string = '';

  constructor(public navCtrl: NavController, public navParams: NavParams, platform: Platform) {

  }

  ionViewDidLoad() {
    console.log('ionViewDidLoad Login');
  }

  login(){
    // Your app login API web service call triggers
    var kmUser = {
        'userId' : this.userId,   //Replace it with the userId of the logged in user
        'password' : this.password,  //Put password here
        'authenticationTypeId' : 1,
        'applicationId' : '22823b4a764f9944ad7913ddb3e43cae1',  //replace "applozic-sample-app" with Application Key from Applozic Dashboard
        'deviceApnsType' : 0    //Set 0 for Development and 1 for Distribution (Release)
    };

    kommunicate.login(kmUser, function(response) {
      console.log("Kommunicate login success response : " + response);
      kommunicate.registerPushNotification((response)=>{
        console.log("Kommunicate Push success response : " + response);
      },()=>{
        console.log("Kommunicate Push failed response : " + response);
      });
       kommunicate.launchConversation(function(response) {
         console.log("Kommunicate launch success response : " + response);
       }, function(response) {
        console.log("Kommunicate launch failure response : " + response);
       });
    }, function(response) {
      console.log("Kommunicate login failure response : " + response);
    });
  }

}

declare var kommunicate: any;
