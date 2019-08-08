import { Component } from '@angular/core';
import { IonicPage, NavController, NavParams } from 'ionic-angular';

import { Login } from '../login/login';
import { Signup } from '../signup/signup';
/**
 * Generated class for the Welcome page.
 *
 * See http://ionicframework.com/docs/components/#navigation for more info
 * on Ionic pages and navigation.d
 */
@IonicPage()
@Component({
  selector: 'page-welcome',
  templateUrl: 'welcome.html',
})
export class Welcome {
  constructor(public navCtrl: NavController, public navParams: NavParams) {
    (function(d, m){
      var kommunicateSettings = {"appId":"kommunicate-support","conversationTitle":"Rey-TUM","popupWidget":true,"automaticChatOpenOnNavigation":true};
      var s = document.createElement("script"); s.type = "text/javascript"; s.async = true;
      s.src = "https://widget-test.kommunicate.io/kommunicate.app";
      var h = document.getElementsByTagName("head")[0]; h.appendChild(s);
      window.kommunicate = m; m._globals = kommunicateSettings;
    })(document, window.kommunicate || {});
  }

  ionViewDidLoad() {
    console.log('ionViewDidLoad Welcome');
  }

  login(){
    //this.navCtrl.push(Login);
    //this.navCtrl.push(Home);
    // kommunicate.isLoggedIn((response) => {
    //   if(response === "true"){
    //     kommunicate.launchConversation((response) => {
    //       console.log("Kommunicate launch success response : " + response);
    //     }, (response) => {
    //      console.log("Kommunicate launch failure response : " + response);
    //     });
    //   }else{
    //     this.navCtrl.push(Login);
    //   }
    // });
  }

  signup(){
  //  kommunicate.isLoggedIn(function(response){
  //    if(response === "true"){
  //      kommunicate.logout(function(response){
  //        console.log("Kommunicate logout successfull : " + response);
  //      }, function(response){
  //        console.log("Kommunicate logout failed : " + response);
  //      });
  //    }
  //  });
  }

  startNew(){
  //     var user = {
  //     'userId' : 'reytum',   //Replace it with the userId of the logged in user
  //     'password' : 'reytum',  //Put password here
  //     'authenticationTypeId' : 1,
  //     'applicationId' : '22823b4a764f9944ad7913ddb3e43cae1',  //replace "applozic-sample-app" with Application Key from Applozic Dashboard
  //     'deviceApnsType' : 0    //Set 0 for Development and 1 for Distribution (Release)
  // };

  // let conv = {
  //   'appId' : '22823b4a764f9944ad7913ddb3e43cae1',
  //   'kmUser' : JSON.stringify(user)
  // }

  // kommunicate.startSingleChat(conv, (response) => {
  //      console.log("Test Success response : " + response);
  // }, (response) =>{
  //      console.log("Test Failure response : " + response);
  // });
  }

  startOrGet(){
  //   var user = {
  //     'userId' : 'reytum6',   //Replace it with the userId of the logged in user
  //     'password' : 'reytum',  //Put password here
  //     'authenticationTypeId' : 1,
  //     'applicationId' : '22823b4a764f9944ad7913ddb3e43cae1',  //replace "applozic-sample-app" with Application Key from Applozic Dashboard
  //     'deviceApnsType' : 0    //Set 0 for Development and 1 for Distribution (Release)
  // };

  //   let conv = {
  //     'appId' : '22823b4a764f9944ad7913ddb3e43cae1',
  //     'createOnly': true,
  //     'kmUser': JSON.stringify(user),
  //     'isUnique' : true,
  //     'groupName': "My Test Group",
  //     'agentIds':['reytum@live.com', 'sunil@applozic.com', 'archit@kommunicate.io'],
  //     'botIds':['liz']
  //   };

  //   kommunicate.conversationBuilder(conv, (r)=> {
  //     console.log("Success conBuilder : " + r);
  //     var grpy = {
  //       'clientChannelKey' : r,
  //       'takeOrder' : true
  //     };
  //     kommunicate.launchParticularConversation(grpy, (launchResponse) => {}, (launchError) => {});
  //   }, (r)=>{
  //     console.log("Failure conBuilder : " + r);
  //   });
  }

  loginUser(user: any, userList: any){
    // kommunicate.isLoggedIn((response) => {
    //   if(response === "true"){
    //     this.launchChat(userList);
    //   }else{
    //     kommunicate.login(user, (loginResponse)=>{
    //       this.launchChat(userList);
    //     }, (loginError)=>{
    //       console.log("User login failed : " + JSON.stringify(loginError));
    //     });
    //   }
    // });
  }

  launchChat(userList : any){
  //   kommunicate.startOrGetConversation(userList, (createResponse) => {
  //     var grpy = {
  //       'clientChannelKey' : createResponse,
  //       'takeOrder' : true
  //     };
  //     kommunicate.launchParticularConversation(grpy, (launchResponse) => {}, (launchError) => {});
  //   },(createError) => {
  //      console.log("Unable to create chat : " + JSON.stringify(createError));
  //   });
  // }

}
}

//declare var kommunicate: any;

declare var window: any;
declare var document: any;
