extends CanvasItem

##Router is a class which helps with  enemy movement. It will set up an array for a grid based on router_grid.
class_name RouterGrid2D

##The grid from which the coordinates will be set. Inside the node, each node is a row, each child is a column.
@export var router_grid : Node
##Any metadata to store from each grid routing node.
@export var metadata : Array[String]

##If the route_grid will not be used for other purposes, you might as well free up a bit of space on the remote console *shrug*
@export var keep_grid_node : bool = false

@export_subgroup("debug")
@export var debug : bool = false
@export var radius : float = 1.0
@export var color : Color

var _grid : Array[Array] #jagged array of Router[]s




func _ready() -> void:
    if router_grid:
        SetGrid()
    
    print("Router grid ready")


func SetGrid() -> void:
    if !router_grid.get_child_count():
        push_error("Router grid is empty")
        breakpoint
        return
    
    for row in router_grid.get_children():
        var new_subarray : Array[Router]

        for column in row.get_children():
            var new_router : Router = Router.new()
            new_router.position = column.global_position

            for meta in metadata:
                new_router.metadata.append(column.get_meta(meta))

            new_subarray.append(new_router)
        
        _grid.append(new_subarray)
    
    if !keep_grid_node:
        router_grid.queue_free()


##EnrouteNode(node = the node to direct towards the next grid position, xy_cords = the grid position as parent,child)[br]
##only returns false if index is out of bounds at call
func EnrouteNode(node : RoutableEnemy2D):
    if node._route_index > node.route.size() -1:
        return false

    for data_order in metadata.size():
        node.set(metadata[data_order],
        _grid[node.route[node._route_index].x][node.route[node._route_index].y].position)
    
    node._route_index += 1

    if node._route_index < node.route.size():
        _SetNodeDirection(node)
    
    return true


func _SetNodeDirection(node : RoutableEnemy2D):
    var difference : Vector2 = (_grid[node.route[node._route_index].x][node.route[node._route_index].y].position - node.global_position)

    node.direction = difference.normalized()
    node.distance_left = difference.length()


func _draw() -> void:
    if debug:
        for data_point in _grid:
            draw_circle(data_point[0], radius, color)





class Router:
    var position : Vector2
    var metadata : Array[Variant]
