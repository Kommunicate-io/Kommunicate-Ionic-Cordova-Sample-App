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
    //this.navCtrl.push(Login);
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
     kommunicate.launchConversation((response)=>{
      var vary = {
        'agentId':'reytum@live.com',
        'botId': 'Hotel-Booking-Assistant'
       };

       kommunicate.startNewConversation(vary, (response) => {
        var grpy = {
          'groupId' : response,
          'takeOrder' : true
        };
  
        console.log("Reytum Launch object : " + JSON.stringify(grpy));
  
        kommunicate.launchParticularConversation(grpy, function(response) {
          console.log("Kommunicate launch success response : " + response);
        }, function(response) {
         console.log("Kommunicate launch failure response : " + response);
        });
         console.log("Kommunicate create conversation successfull : " + response);
      },(response) => {
        console.log("Kommunicate create conversation failed : " + response);
      });
     },(response)=>{

     });
  }

  startOrGet(){
    var user = {
      'userId' : 'reytum',   //Replace it with the userId of the logged in user
      'password' : 'reytum',  //Put password here
      'authenticationTypeId' : 1,
      'applicationId' : '22823b4a764f9944ad7913ddb3e43cae1',  //replace "applozic-sample-app" with Application Key from Applozic Dashboard
      'deviceApnsType' : 0    //Set 0 for Development and 1 for Distribution (Release)
  };

  let conv = {
    'appId' : '22823b4a764f9944ad7913ddb3e43cae1',
    'kmUser' : JSON.stringify(user)
  }

  kommunicate.startSingleChat(conv, (response) => {
       console.log("Test Success response : " + response);
  }, (response) =>{
       console.log("Test Failure response : " + response);
  });
  }

  loginUser(user: any, userList: any){
    kommunicate.isLoggedIn((response) => {
      if(response === "true"){
        this.launchChat(userList);
      }else{
        kommunicate.login(user, (loginResponse)=>{
          this.launchChat(userList);
        }, (loginError)=>{
          console.log("User login failed : " + JSON.stringify(loginError));
        });
      }
    });
  }

  launchChat(userList : any){
    kommunicate.startOrGetConversation(userList, (createResponse) => {
      var grpy = {
        'clientChannelKey' : createResponse,
        'takeOrder' : true
      };
      kommunicate.launchParticularConversation(grpy, (launchResponse) => {}, (launchError) => {});
    },(createError) => {
       console.log("Unable to create chat : " + JSON.stringify(createError));
    });
  }
}

declare var kommunicate: any;
declare var broadcaster: any;
