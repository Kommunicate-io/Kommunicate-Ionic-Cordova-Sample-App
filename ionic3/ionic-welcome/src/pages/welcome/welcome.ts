import {
  Component
} from '@angular/core';
import {
  IonicPage,
  NavController,
  NavParams
} from 'ionic-angular';

import {
  Login
} from '../login/login';
import {
  Signup
} from '../signup/signup';
// *
//  * Generated class for the Welcome page.
//  *
//  * See http://ionicframework.com/docs/components/#navigation for more info
//  * on Ionic pages and navigation.d
 
@IonicPage()
@Component({
  selector: 'page-welcome',
  templateUrl: 'welcome.html',
})
export class Welcome {
  appId: string = "22823b4a764f9944ad7913ddb3e43cae1";

  constructor(public navCtrl: NavController, public navParams: NavParams) {
    
  }

  ionViewDidLoad() {
    console.log('ionViewDidLoad Welcome');
  }

  login() {
    //  var kmUser = {
    //     'userId' : 'reytum',   //Replace it with the userId of the logged in user
    //     'password' : 'reytum',  //Put password here
    //     'authenticationTypeId' : 1,
    //     'applicationId' : this.appId ,  //replace "applozic-sample-app" with Application Key from Applozic Dashboard
    //     'deviceApnsType' : 0    //Set 0 for Development and 1 for Distribution (Release)
    // };

    // kommunicate.login(kmUser, (r)=>{
    //   console.log("Kommunicate login successfull : " + r);
    // }, (e)=>{
    //   console.log("Kommunicate logout failed : " + e);
    // });
   kommunicate.isLoggedIn((response) => {
       console.log("Received isLoggedIn response : " + response)
      if (response === "true") {
        kommunicate.launchConversation((response) => {
          console.log("Kommunicate launch success response : " + response);
        }, (response) => {
          console.log("Kommunicate launch failure response : " + response);
        });
      } else {
        this.navCtrl.push(Login);
      }
    });
  }

  signup() {
    kommunicate.isLoggedIn(function (response) {
      if (response === "true") {
        kommunicate.logout(function (response) {
          console.log("Kommunicate logout successfull : " + response);
        }, function (response) {
          console.log("Kommunicate logout failed : " + response);
        });
      }
    });
  }

  startNew() {
    // var user = {
    //   'userId': 'reytum', //Replace it with the userId of the logged in user
    //   'password': 'reytum', //Put password here
    //   'authenticationTypeId': 1,
    //   'applicationId': this.appId, //replace "applozic-sample-app" with Application Key from Applozic Dashboard
    //   'deviceApnsType': 0 //Set 0 for Development and 1 for Distribution (Release)
    // };

    // let conv = {
    //   'appId': this.appId,
    //   'kmUser': JSON.stringify(user)
    // }

    // kommunicate.startSingleChat(conv, (response) => {
    //   console.log("Test Success response : " + response);
    // }, (response) => {
    //   console.log("Test Failure response : " + response);
    // });

      let convObj = {
        'clientChannelKey' : '24930820', //pass the clientChannelKey here
        'takeOrder' : true //skip chat list on back press, pass false if you want to show chat list on back press
      };

    kommunicate.launchParticularConversation(convObj, (response) => {
       console.log('Successfully launched conversation with conversation Id : ' + response)
    }, (response) => {
       console.log('Failed to launch conversation with conversation Id : ' + response)
    });
  }

  startOrGet() {
    var user = {
      'userId': 'reytum6', //Replace it with the userId of the logged in user
      'password': 'reytum', //Put password here
      'authenticationTypeId': 1,
      'applicationId': this.appId, //replace "applozic-sample-app" with Application Key from Applozic Dashboard
      'deviceApnsType': 0 //Set 0 for Development and 1 for Distribution (Release)
    };

    let conv = {
      'appId': this.appId,
      'createOnly': true,
      'withPreChat': true,
      'isUnique': true,
      'groupName': "My Test Group"
    };

    kommunicate.conversationBuilder(conv, (r) => {
      console.log("Success conBuilder : " + r);
      var grpy = {
        'clientChannelKey': r,
        'takeOrder': true
      };
      kommunicate.launchParticularConversation(grpy, (launchResponse) => {}, (launchError) => {});
    }, (r) => {
      console.log("Failure conBuilder : " + r);
    });
  }

  // launchChat(userList: any) {
  //   kommunicate.startOrGetConversation(userList, (createResponse) => {
  //     var grpy = {
  //       'clientChannelKey': createResponse,
  //       'takeOrder': true
  //     };
  //     kommunicate.launchParticularConversation(grpy, (launchResponse) => {}, (launchError) => {});
  //   }, (createError) => {
  //     console.log("Unable to create chat : " + JSON.stringify(createError));
  //   });
  // }
}

declare var kommunicate: any;