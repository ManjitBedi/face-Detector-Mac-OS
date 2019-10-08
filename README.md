The code is hacked from an iOS sample code from Apple with support added to upload images to Firebase.   

[Tracking the User’s Face in Real Time](https://developer.apple.com/documentation/vision/tracking_the_user_s_face_in_real_time)

The Firebase support is achieved using  community Firebase code & Cocoapods.

The code was orginally intended to be used in an art installation piece but the app was crashing in the Vision Framework - it went pear shaped for various reasons.  The code was hacked to work around the crash issue but this changed the desired behaviour of the app.  

In various places, the app will do some scaling & image compositing.  This code would benefit from re-factoring.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.




