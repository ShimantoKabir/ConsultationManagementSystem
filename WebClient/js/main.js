// let serverBaseUrl = "http://192.168.43.132:8080";
// let webClientBaseUrl = "http://192.168.43.132/consultationmanagementsystem/webclient";

let serverBaseUrl = "http://192.168.43.179:8080";
let webClientBaseUrl = "http://192.168.43.132/consultationmanagementsystem/webclient";

// let serverBaseUrl = "http://3.20.119.226:8080";
// let webClientBaseUrl = "http://3.20.119.226/cms/index.html";

const firebaseConfig = {
  apiKey: "AIzaSyDHEaJDFAJUarR4_Hpoamt96EFG22Vd7XE",
  authDomain: "consultationmanagementsy-7b77c.firebaseapp.com",
  databaseURL: "https://consultationmanagementsy-7b77c.firebaseio.com",
  projectId: "consultationmanagementsy-7b77c",
  storageBucket: "consultationmanagementsy-7b77c.appspot.com",
  messagingSenderId: "996664131953",
  appId: "1:996664131953:web:6ee0c8eeb5c40243d976d0",
  measurementId: "G-7G0SBJHF7B"
};

var consultant = firebase.initializeApp(firebaseConfig,"consultant");
console.log("database name = ",consultant.name); 
var db = consultant.firestore();