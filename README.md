# PiVolumeSwift

This is the project we'll look at at the [Learn Swift L.A.](https://www.meetup.com/LearnSwiftLA/)'s [iOS App Development Basics](https://www.meetup.com/LearnSwiftLA/events/vjjzxmyxjbjb/) meeting on June 6, 2018.

It all started for me when was looking for a way to remote-control the audio playback volume out of my two Raspberry Pis. I found I could set the volume from the Mac Terminal, like this...:

![ssh in Terminal](https://github.com/rainerstandke/PiVolumeSwift/blob/master/imagesForReadme/Terminal.png)

... where the line `amixer -c 0 cset numid=6 88` sets the volume to a value of 88, as confirmed by this line:   `: values=88,88`.

Enter PiVolumeSwift, a project tailor-made for my own home setup, and probably not very useful for anyone else - especially if you don't have a Raspberry Pi set up exactly like mine. I have been using versions of it for a good, long while.

Here is the main screen:

![volume view controller](https://github.com/rainerstandke/PiVolumeSwift/blob/master/imagesForReadme/Volume.png)

And this is where connection parameters need to be entered:

![connection settings](https://github.com/rainerstandke/PiVolumeSwift/blob/master/imagesForReadme/Settings.png)

At the meeting we'll have a Raspberry Pi available to play with, and we will discuss the code and what does what.
