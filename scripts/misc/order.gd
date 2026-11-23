class_name Order

var table: Table
var order_from_left: bool
var order_from_right: bool

func _init(table: Table, order_from_left: bool, order_from_right) -> void:
    self.table = table
    self.order_from_left = order_from_left
    self.order_from_right = order_from_right