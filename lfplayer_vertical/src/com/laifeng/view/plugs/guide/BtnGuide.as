package com.laifeng.view.plugs.guide
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	
	public class BtnGuide extends Sprite
	{
		
		
		private var _baseAlpha:Number = 0.7;
		
		
		public function BtnGuide()
		{
			super();
			
			this.buttonMode = true;
			
			
			var gph:Graphics = this.graphics;
			gph.beginFill(0x000000,0.5);
			gph.drawCircle(8,12,25);
			gph.endFill();
			
			
			//gph.lineStyle(1,0xFFFFFF); 
			gph.beginFill(0xFFFFFF);
			
			gph.moveTo(0,0);
			gph.lineTo(0,24);
			gph.lineTo(20,12);
			gph.lineTo(0,0);
			gph.endFill();
			
			
			this.alpha = _baseAlpha;
			
			this.addEventListener(MouseEvent.MOUSE_OVER,overHandler);
			this.addEventListener(MouseEvent.MOUSE_OUT,outHandler);
			
		}
		
		
		
		private function overHandler(event:MouseEvent):void{
			this.alpha = 1;
		}
		
		private function outHandler(event:MouseEvent):void{
			this.alpha = _baseAlpha;
		}
		
		
		
		
		
		
	}
}