extends Node

func fadeInAndMakeVisible(nodeToTween: Node, fadeTime := .5):
	nodeToTween.set_visible(1)
	var tween: Tween = nodeToTween.create_tween()
	tween.tween_property(nodeToTween, "modulate", Color(1,1,1,1), fadeTime)
	
func fadeInFadeOut(nodeToTween: Node, fadeInTime := .1, fadeOutTime := .1):
	nodeToTween.set_visible(1)
	var tween: Tween = nodeToTween.create_tween()
	tween.tween_property(nodeToTween, "modulate", Color(1,1,1,1), fadeInTime)
	await tween.finished
	
	var tween2 = nodeToTween.create_tween()
	tween2.tween_property(nodeToTween, "modulate", Color(1,1,1,0), fadeOutTime)
	await tween.finished
	
func fadeOutAndDestroy(nodeToTween: Node, fadeTime := .5):
	var tween: Tween = nodeToTween.create_tween()
	tween.tween_property(nodeToTween, "modulate", Color(1,1,1,0), fadeTime)
	tween.tween_callback(nodeToTween.queue_free)
	
func fadeOutAndHide(nodeToTween: Node, fadeTime := .5):
	var tween: Tween = nodeToTween.create_tween()
	tween.tween_property(nodeToTween, "modulate", Color(1,1,1,0), fadeTime)
	tween.tween_callback(func(): nodeToTween.set_visible(false))
	
	return tween
