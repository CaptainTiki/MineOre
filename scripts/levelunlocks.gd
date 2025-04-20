extends Resource
class_name LevelUnlocks

# This resource defines XP thresholds and unlocks for each level.
# The level_data dictionary should be structured as:
# {
#     level: {
#         "xp_threshold": int,
#         "unlocks": [
#             {"type": String, "id": String},
#             ...
#         ]
#     },
#     ...
# }
var level_data: Dictionary = {}

# Returns the unlocks for a given level, or an empty array if the level doesn't exist
func get_unlocks_for_level(level: int) -> Array:
	if level in level_data:
		return level_data[level]["unlocks"]
	return []

# Returns the XP threshold for a given level, or -1 if the level doesn't exist
func get_xp_threshold_for_level(level: int) -> int:
	if level in level_data:
		return level_data[level]["xp_threshold"]
	return -1
