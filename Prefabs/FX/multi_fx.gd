class_name MultiFX extends Node2D

@export var destroy_on_finished:bool = false;
@export var sub_fxs:Array[GPUParticles2D];

var finished_count:int = 0;

func emit():
	for fx in sub_fxs:
		if(!fx.finished.is_connected(on_sub_fx_finished)):
			fx.finished.connect(on_sub_fx_finished);
		fx.emitting = true;

func on_sub_fx_finished():
	finished_count += 1;
	if(finished_count == sub_fxs.size()):
		finished_count == 0;
		if(destroy_on_finished):
			self.queue_free();
