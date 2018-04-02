import { Component } from '@angular/core';
import { IonicPage, NavController, NavParams } from 'ionic-angular';

import { Login } from '../login/login';
import { Signup } from '../signup/signup';
/**
 * Generated class for the Welcome page.
 *
 * See http://ionicframework.com/docs/components/#navigation for more info
 * on Ionic pages and navigation.
 */
@IonicPage()
@Component({
  selector: 'page-welcome',
  templateUrl: 'welcome.html',
})
export class Welcome {

  constructor(public navCtrl: NavController, public navParams: NavParams) {
  }

  ionViewDidLoad() {
    console.log('ionViewDidLoad Welcome');
  }

  login(){
    kommunicate.isLoggedIn((response) => {
      if(response === "true"){
        kommunicate.launchConversation((response) => {
          console.log("Kommunicate launch success response : " + response);
        }, (response) => {
         console.log("Kommunicate launch failure response : " + response);
        });
      }else{
        this.navCtrl.push(Login);
      }
    });
  }

  signup(){
   kommunicate.isLoggedIn(function(response){
     if(response === "true"){
       kommunicate.logout(function(response){
         console.log("Kommunicate logout successfull : " + response);
       }, function(response){
         console.log("Kommunicate logout failed : " + response);
       });
     }
   });
  }

  startNew(){
    let vary = {
      'agentId':'reytum@live.com',
      'botId': 'Hotel-Booking-Assistant'
     };

    kommunicate.startNewConversation(vary, (response) => {
      let grpy = {
        'groupId' : JSON.parse(response).key,
        'takeOrder' : true
      };

      kommunicate.launchParticularConversation(grpy, function(response) {
        console.log("Kommunicate launch success response : " + response);
      }, function(response) {
       console.log("Kommunicate launch failure response : " + response);
      });
      
       console.log("Kommunicate create conversation successfull : " + response);
    },(response) => {
      console.log("Kommunicate create conversation failed : " + response);
    });
  }

}

declare var kommunicate: any;
