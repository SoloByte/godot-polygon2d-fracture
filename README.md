# godot-polygon2d-fracture



## Info

Two simple scripts for fracturing polygons. PolygonFracture.gd is the actual script that fractures polygons. PolygonLib.gd adds nice helper functions for polygons like calculateArea, triangulate, getRandomPointsInPolygon, getBoundingRect, etc.

The scripts are located in the polygon-fracture folder.
The demo project is located in the demo folder.

Releases with the -demo ending contain the project + the polygon-fracture folder with the two final scripts, all other releases just have zip folder with the two final scripts.

PS: To test the actual perfomance of the cutting just maximize the min area because then no rigidbodies are spawned. You wont see any fracture shards either, though. (spawning and despawning that many rigidbodies at once causes the biggest performance hit - pooling would aleviate that for some part)

## Fracturing Methods

There are two different systems for fracturing polygons.
 - Delaunay Fracture -> uses the delaunay triangulation to calculate random triangles inside the polygon. DelaunyFractureConvex asumes the polygon is convex and     DelaunyFractureRectangle asumes the polygon is a rectangle (convex/rectangle makes the fracturing simpler). Produces triangle fractures.
 - Fracture -> uses randomly generated cut lines to actually cut the polygon. Fracture and Fracture simple have different methods of obtaining the random cut lines but are otherwise the same. Produces polygon fractures.

### Delaunay System
![](gifs/polygon2d-delauny-fracture-01.gif)

### Cut Line System
![](gifs/polygon2d-fracture-simple-01.gif)



I need the fracturing for my game but I thought I share it with anyone interestered. My method is not the best or most performant method out there, and also implemented via GDScript (for ease of use), so don´t expect any performance miracles. There are other solutions out there, but I did not find a simple solution for fracturing 2d polygons in the way I wanted. Maybe sometime in the future I will look into Voronoi fractures, to make the fractures look better. (Now the polygon is just randomly fractured)



## Other Solutions
- goost (https://github.com/goostengine/goost) for example, but requires building Godot from source
- Godot-3-2D-Destructible-Objects (https://github.com/hiulit/Godot-3-2D-Destructible-Objects) but only works for sprites
