# godot-polygon2d-fracture



## UPDATES
- UPDATE v1.1.0 adds cutting of polygons.



## Info

Works with GodotEngine 3.2+

Two simple scripts for fracturing and cutting polygons. PolygonFracture.gd is the actual script that fractures/cuts polygons. PolygonLib.gd adds nice helper functions for polygons like calculateArea, triangulate, getRandomPointsInPolygon, getBoundingRect, etc.

The final scripts are located in the polygon2d-fracture folder.
The demo project is located in the demo folder.

PS: To test the cutting's actual perfomance just increase the min area (around 5000) because then less rigid bodies are spawned. You wont see many fracture shards either, though. (spawning and despawning that many rigid bodies at once cause the biggest performance hit - pooling would alleviate that for some part)



## Cut Method

There is just one cut method. It uses 1 polygon as source and 1 polygon as cut shape. The intersected shape (the parts overlapping in both polygons) can be fractured if desired. I also added helper funcs to PolygonLib.gd to create simple polygon shapes (currently: rectangle, circle, beam).

![](gifs/polygon2d-cutfracture-showcase-02.gif)


## Fracturing Methods

There are two different systems for fracturing polygons.
 - Delaunay Fracture -> uses the delaunay triangulation to calculate random triangles inside the polygon. DelaunyFractureConvex assumes the polygon is convex and     DelaunyFractureRectangle assumes the polygon is a rectangle (convex/rectangle makes the fracturing simpler). Produces triangle fractures.
 - Fracture -> uses randomly generated cut lines to actually cut the polygon. Fracture and Fracture simple have different methods of obtaining the random cut lines but are otherwise the same. Produces polygon fractures.

### Delaunay System
![](gifs/polygon2d-delauny-fracture-01.gif)

### Cut Line System
![](gifs/polygon2d-fracture-simple-01.gif)



I need the fracturing for my game but I thought I share it with anyone interested. My method is not the best or most performant method out there, and also implemented via GDScript (for ease of use), so don´t expect any performance miracles. There are other solutions out there, but I did not find a simple solution for fracturing 2d polygons in the way I wanted. Maybe sometime in the future, I will look into Voronoi fractures, to make the fractures look better. (Now the polygon is just randomly fractured)



## Other Solutions
- goost (https://github.com/goostengine/goost) for example, but requires building Godot from source
- Godot-3-2D-Destructible-Objects (https://github.com/hiulit/Godot-3-2D-Destructible-Objects) but only works for sprites
