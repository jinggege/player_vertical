package com.laifeng
{
    import com.laifeng.config.LiveConfig;
    import com.laifeng.config.ModuleKey;
    import com.laifeng.controls.DMCenter;
    import com.laifeng.controls.DataModule;
    import com.laifeng.controls.LFExtenrnalInterface;
    import com.laifeng.controls.UIManage;
    
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.external.ExternalInterface;
    import flash.system.Security;
    
    import lf.media.core.util.Console;
    import lf.media.core.util.EnterframeTimer;
    
	
	/**********************************************************
	 * 播放器入口
	 * 
	 * Author         : mj
	 * Log :
	 * 
	 *    20160808
	 *               1. cv1统计接口添加 start_time  end_time
	 * 
	 ***********************************************************/
    
    //[SWF(width = "520", height = "390",frameRate="24")]
	[SWF(frameRate="50",backgroundColor="#000000")]
    public class LFplayerV extends Sprite {
        
        public function LFplayerV() {
            Security.allowDomain("*");
			Security.allowInsecureDomain("*");
			Console.isDebug = false;
			setStageMode();
			
			
			var flashvars:Object = this.loaderInfo.parameters;
			var jsNameSpace:String = flashvars["callbackNamespace"];
			
			if(jsNameSpace == null){
				jsNameSpace = LiveConfig.get.jsNameSpace;
			}
			
			LiveConfig.get.jsNameSpace = jsNameSpace+".";
			
			LFExtenrnalInterface.get.start();
			
			//UIManage.get.start(this.stage);
			DataModule.get.init();
			EnterframeTimer.get.start(this.stage);
			
			ExternalInterface.addCallback("init",init);
			ExternalInterface.call(LiveConfig.get.jsNameSpace+"playerLoadCompleted");
        }
		
        public function init(option : Object):int{
			_dmCenter = DataModule.get.getModule(ModuleKey.DM_LIVECORE) as DMCenter;
			_dmCenter.initConfig(option);
			UIManage.get.start(this.stage);
			UIManage.get.playerInited();
			
			LiveConfig.liveStatus = 0;
			
			return 1;
        }
		
        private function setStageMode():void {
            stage.scaleMode   = StageScaleMode.NO_SCALE;
            stage.align             = StageAlign.TOP_LEFT;
            stage.tabChildren = false;
            stage.showDefaultContextMenu = false;
        }
		
		
		private var _dmCenter:DMCenter;
        
    }
}