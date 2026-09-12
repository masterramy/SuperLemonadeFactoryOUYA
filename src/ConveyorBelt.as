package
{
	import org.flixel.*;
	import flash.geom.Rectangle;
	import org.flixel.plugin.photonstorm.*;
	

	public class ConveyorBelt extends FlxSprite
	{
		
		[Embed(source="../data/conveyorBeltBlockWithEnds.png")] private var ImgConveyorBelt:Class;
		
		/**
		* The speed at which the conveyor belt travels.
		*/
		public var _speed:Number;
		
		public function ConveyorBelt(X:int,Y:int, Speed:Number)
		{
			
			loadGraphic(ImgConveyorBelt, false, false,50,20);
			
			this.x = X;
			this.y = Y;
			_speed = Speed;
			immovable = true;
			
			FlxScrollZone.add(this, new Rectangle(5, 0, 40, 20), _speed, 0, true);	
			
		}
		
		override public function update():void
		{
			FlxScrollZone.updateX(this, _speed);
			
			super.update();
		}
		
		override public function destroy():void
		{
			
			// Important! Unregister only this conveyor from the shared scrolling-image plugin.
			FlxScrollZone.remove(this);
			
			super.destroy();
		}
		
		public function setSpeed(Speed:Number):void {
			
		}
		
		
	}
}