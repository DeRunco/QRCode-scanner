# Use of QRScanner


## Goal
This app starts the camera and search for QR codes using Apple AVCaptureMetadataOutput API, and brings a UI when tapping one of them.

The app can store QR codes for the user to use them afterward.

The point of this app was to play around with UI/UX, camera output and of course Swift.

## QR Code

Use an external QR code generator to generate your glyph. Be sure to set it to generate a `Text` QR code.

## The App
The application displays an overlay on maximum 4 QR codes simultaneously (Apple's limit). Tapping on a code will display a view that allows you to `save` the QR code you just scanned, cancel or launch (the app tries to `openURL:` with it).

