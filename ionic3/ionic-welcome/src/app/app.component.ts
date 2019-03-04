import { Component } from '@angular/core';
import { Platform } from 'ionic-angular';
import { StatusBar } from '@ionic-native/status-bar';
import { SplashScreen } from '@ionic-native/splash-screen';

import { Welcome } from '../pages/welcome/welcome';

@Component({
  templateUrl: 'app.html'
})
export class MyApp {
  rootPage:any = Welcome;

  constructor(platform: Platform, statusBar: StatusBar, splashScreen: SplashScreen) {
    platform.ready().then(() => {
      // Okay, so the platform is ready and our plugins are available.
      // Here you can do any higher level native things you might need.
      // We are registering the native event listener here 
      // so that we can check for either startNewConversation or logout event from the native screen
    if(platform.is('android')){
      //this is a brodcaster plugin. Add it using command 'ionic cordova plugin add cordova-plugin-broadcaster'
      //this KmStartNewConversation event is fired when the start new conversation button is clicked on the chat list screen
      broadcaster.addEventListener("KmStartNewConversation", (e) => {
          //once the event is received we can do whatever we want.
          this.createNewChat();
       });
      }
      statusBar.styleDefault();
      splashScreen.hide();
    });
  }

  createNewChat(){
    let convInfo = {
     'agentIds':['reytum@live.com'],  //Array of agentIds
     'botIds': ['liz']  //Array of botIds
    };
    
 //Creating a new conversation
 kommunicate.startNewConversation(convInfo, (response) => {
     let convObj = {
       'clientChannelKey' : response,
       'takeOrder' : true
     };
     //launching the conversation as soon as it gets created
    kommunicate.launchParticularConversation(convObj, function(response) {
     }, function(response) {
     });
     console.log("Kommunicate create conversation success: " + response);
   },(response) => {
     console.log("Kommunicate create conversation failed : " + response);
   });
  }
}

declare var kommunicate : any;
declare var broadcaster : any;
