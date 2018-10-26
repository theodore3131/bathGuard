#  BFP -- SoundWave

### Bathroom Faint Protection

As some people are potentially risky of get faint during their bath time,

how to detect this kind of emergency without invading the users privacy was difficult to do before. Even infrared ray is largely unaccepted by most people as this method may extract the image of their whole bodyshape if the ray scan the user all the time in the bathroom. Let alone using computer vision.

Therefore we come up with the idea that we may use the sound to detect this kind of risk. As we all know, sound of emergency differenciate dramatically from that of regular bathing. If that happens, there would be a suddenly change in the sound followed by normal waves as the user is faint. 

So we can tell from the soundwave graph whether the user is safe.

This app will listen to the sound in the bathroom and perform systematic ananysis based on the built-in Neurual network model. If the match ratio of the sound detected and the stored model, then the app will make urgent call and try to evoke the user by calling his name.