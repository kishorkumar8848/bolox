<div align="center">
  <img src="assets/icon/app_icon.png" alt="BoloX Logo" width="150"/>
  <h1>BoloX - Offline AI Walkie-Talkie</h1>
  <p><strong>Smart India Hackathon (SIH) Submission</strong></p>
  <p><i>Breaking language and connectivity barriers in critical environments.</i></p>
</div>

<hr/>

## 🎯 Problem Statement
In remote areas, disaster zones, or highly congested events, standard cellular networks frequently fail. When communication is most critical, first responders, disaster management teams, and local citizens are left entirely disconnected. Furthermore, even when communication is possible, language barriers across India's diverse linguistic landscape prevent critical information from being understood.

## 🚀 The Solution: BoloX
**BoloX** is a 100% offline, peer-to-peer walkie-talkie application built to operate completely independent of the internet or cellular networks. By leveraging local Bluetooth and Wi-Fi Direct protocols, BoloX allows users to communicate via voice across distances. 

More than just a radio, BoloX features a built-in **AI Translation Engine**. A user can speak in Tamil, and the receiver will hear the message instantly translated into Hindi—all happening directly on the device hardware without a single byte of internet data.

### ✨ Key Features
- **📻 100% Offline Communication:** Uses Google Nearby Connections API for high-bandwidth peer-to-peer audio streaming in Airplane Mode.
- **🗣️ On-Device AI Translation:** Seamlessly translates voice messages across **10 Indian Languages** (Hindi, Gujarati, Marathi, Kannada, Malayalam, Tamil, Telugu, Odia, Bengali, English).
- **🧭 Offline Location Tracking:** Shares GPS coordinates via encrypted mesh packets, displaying the exact distance (e.g., "450m") and cardinal direction (e.g., "North-East") of the peer.
- **🔄 Dual Modes:** Switch seamlessly between continuous "Phone Mode" (Duplex) and push-to-talk "Walkie-Talkie Mode" (Half-Duplex).
- **🚨 Emergency SOS:** Broadcast high-priority distress signals overriding standard communication channels.
- **⚡ Hardware Accelerated:** Uses `onDevice: true` Android Speech Recognition to process STT directly on the phone's NPU/CPU.

---

## 🛠️ Technology Stack
- **Framework:** Flutter / Dart
- **Networking:** Google Nearby Connections API (`nearby_connections`)
- **Machine Learning (Translation):** Google ML Kit Translation (`google_mlkit_translation`)
- **Speech Processing:** Android Native SpeechRecognizer (STT) & TextToSpeech (TTS)
- **Geolocation:** `geolocator` with local coordinate math

---

## 📥 Installation & Setup (For Judges)

> **IMPORTANT:** Because BoloX relies on heavy Machine Learning models that cannot be bundled into the APK per Google's policies, you **must complete a one-time setup on Wi-Fi** before testing Airplane Mode.

1. **Install the APK:** Download and install `app-release.apk` on two separate Android devices.
2. **Connect to Wi-Fi:** Open the app on both devices.
3. **Run Offline Setup:** On the main screen, tap the **"OFFLINE SETUP (REQUIRED FIRST)"** button.
4. **Cache Models:** Tap **"Download Missing Models"**. The app will securely download the translation matrices for all 10 languages directly to the phone's storage.
5. **Configure Android Hardware:** Tap the **"OPEN ANDROID SETTINGS"** button on the setup screen. 
   - Navigate to *Voice Typing* and download the Offline Speech packs for the testing languages.
   - Navigate to *Text-to-speech output* and ensure the voice data is installed.
6. **Go Dark:** Turn on **Airplane Mode** on both devices.
7. **Test BoloX:** Enter the app, select Sender/Receiver, connect the devices via the peer-to-peer radar, and start speaking!

---

## 🏗️ Architecture Flow
1. **Audio Capture:** Audio is recorded via mic and processed by the offline Android Speech-to-Text engine.
2. **Packetization:** The recognized text string is serialized into a custom binary packet (CRC checked).
3. **Transmission:** The packet is fired across the Bluetooth/Wi-Fi Direct mesh payload via Nearby Connections.
4. **Reception & Translation:** The receiving device catches the payload, passes the text to the Google ML Kit On-Device Translator, and converts it to the receiver's selected language.
5. **Playback:** The translated text is passed to the Android TTS engine and spoken aloud to the user.

---

<div align="center">
  <p>Built with ❤️ for the Smart India Hackathon</p>
</div>
