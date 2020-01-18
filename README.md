# TD-Grass

This component allows you to create fields of grass.  There are parameters to change most aspects of the look and behavior. 

To create wind and move the grass, create two tops with a width and height of the "Grass Density" parameter. Only the red channel will be used.
One top will be the X direction, one will be the Z direction. .5 is the resting state.

You can also input your own models. Before inserting a new model you may want to lower the grass density so your computer doesn't blow up.

We can use 4 textures for our grass which get randomly selected. Inside the main component you will see four "null_grass_Tex*", each with their own bump map. To change the look of you grass, swap whatever you want into those.
