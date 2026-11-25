## Represents a table-cleaning request for the bartender when an NPC leaves a stool.
class_name CleanTableRequest

var table: Table
var request_from_left: bool
var request_from_right: bool

func _init(table: Table, request_from_left: bool, request_from_right) -> void:
    self.table = table
    self.request_from_left = request_from_left
    self.request_from_right = request_from_right