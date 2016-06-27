package com.laifeng.view.controlbar.showroom
{
	import com.laifeng.config.LiveConfig;
	import com.laifeng.controls.UIManage;
	import com.laifeng.view.controlbar.base.BaseControlBar;
	
	import flash.display.StageDisplayState;
	
	public class CBshowroom extends BaseControlBar
	{
		/**
		 * 秀场 control bar
		 * 
		 */
		public function CBshowroom()
		{
			super();
		}
		
		
		override protected function layout():void{
			
			super.layout();
			
			_btnEffectStatus.x = _btnScreenStatus.x + _btnScreenStatus.width+SPACE;
		}
		
		
		override public function resize(w:int,h:int):void{
			super.resize(w,h);
			if(UIManage.get.stage.displayState == StageDisplayState.NORMAL){
				_btnScreenStatus.status =_btnScreenStatus.STATUS_NOMAL;
			}
			
			_btnEffectStatus.x = w - _btnEffectStatus.width - 10;
		}
		
		
		
	}
}