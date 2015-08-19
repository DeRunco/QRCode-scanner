# Use of QRScanner


## Goal
The goal of this app is to start the UniversalApp without bothering with webpage edition. The app's sources are available in the gitlab, and can be recompiled by a Mac using Xcode.

## Schemes?
URL Schemes are strings. 

Valid scheme parameters are explained [in the gitLab](https://git.core.cloud.weemo.com/misc/universalapp/blob/master/scheme.md). This document is internal documentation.

The official external doc is [available on the docs site](https://docs.sightcall.com/gd/client-sdks/universal-sdk/).

### Examples

This one will authenticate the app on ppr/2/ (with a valid appid), using the `Six Digits` mode and immediately calls the PIN specified in the `pin` parameter. Additionaly, the app will be using the rear camera, displaying the outgoing picture in the frame and the incoming picture in PiP mode.

`sightcall://rtcc/ppr/2/?appid=dci3ravydkq1&pin=077331&mode=sixdigits&buttons=013469&videoout=rear&videofull=out&videosmall=in`

This one will authenticate the app on /ppr/2/ (with a valid appid) as an external of user `user1` and will call this user as soon as it is authenticated. The app will use the front camera, display the captured picture in PiP mode and the incoming picture in full frame.
`sightcall://rtcc/ppr/2/?appid=dci3ravydkq1&mode=phone&uid=user1&calleeid=user1&videoout=front&videofull=in&videosmall=out`

## QR Code?

Use an external QR code generator to generate your glyph, or the internal tool on [static dev](http://static-dev.weemo.com/qrcode/qrcode.html) maintained by Simon.

If you are using an external tool, be sure to set it to generate a `Text` QR code, and not an `URL` qr code.

## The App
The application displays an overlay on maximum 4 QR codes simultaneously. Tapping on a code will display a view that allows you to `save` the URL you just scanned, cancel or launch.

Saving the URL will put it in the list available by tapping the top right button. Tap on an entry of this list to display the view that allows to launch/cancel again. 


