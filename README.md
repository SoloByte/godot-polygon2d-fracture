# godot-polygon2d-fracture



Two simple scripts for fracturing polygons. PolygonFracture.gd is the actual script that fractures polygons. PolygonLib.gd adds nice helper functions for polygons like calculateArea, triangulate, getRandomPointsInPolygon, getBoundingRect, etc.


The scripts are located in the polygon-fracture folder.
The demo project is located in the demo folder.


Releases with the -demo ending contain the project + the polygon-fracture folder with the two final scripts, all other releases just have zip folder with the two final scripts.


I need the fracturing for my game but I thought I share it with anyone interestered. My method is not the best or most performant method out there, and also implemented via GDScript (for ease of use), so don´t expect any performance miracles. There are other solutions out there, but I did not find a simple solution for fracturing 2d polygons in the way I wanted. Maybe sometime in the future I will look into Voronoi fractures, to make the fractures look better. (Now the polygon is just randomly fractured)



Other Solutions:
- goost (https://github.com/goostengine/goost) for example, but requires building Godot from source
- Godot-3-2D-Destructible-Objects (https://github.com/hiulit/Godot-3-2D-Destructible-Objects) but only works for sprites
