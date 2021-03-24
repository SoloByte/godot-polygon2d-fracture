# godot-polygon2d-fracture


------NOT FINISHED------
For now it is just a test project without the final script to use in any project.
------------------------


A simple script for fracturing polygons. Also adds nice helper functions for polygons like calculateArea, triangulate, getRandomPointsInPolygon, getBoundingRect)



I need the fracturing for my game but I thought I share it with anyone interestered. My method is not the best or most performant method out there, and also implemented via GDScript (for ease of use), so don´t expect any performance miracles. There are other solutions out there, but I did not find a simple solution for fracturing 2d polygons in the way I wanted. Maybe sometime in the future I will look into Voronoi fractures, to make the fractures look better. (Now the polygon is just randomly fractured)



Other Solutions:
- goost (https://github.com/goostengine/goost) for example, but requires building Godot from source
- Godot-3-2D-Destructible-Objects (https://github.com/hiulit/Godot-3-2D-Destructible-Objects) but only works for sprites
