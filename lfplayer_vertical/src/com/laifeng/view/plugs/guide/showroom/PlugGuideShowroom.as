package com.laifeng.view.plugs.guide.showroom
{
	import com.adobe.json.JSON;
	import com.laifeng.config.LiveConfig;
	import com.laifeng.interfaces.IPlugin;
	import com.laifeng.view.plugs.control.SimpleUrlLoader;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.media.Video;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	/**
	 * 插件:正在直播的直播间推荐 只显示前三名 
	 * 
	 */
	
	public class PlugGuideShowroom extends Sprite implements IPlugin
	{
		
		public var id:int = 0;
		public const MAX_W:int = 320;
		
		private const nextIssueUrl:String = "http://v.laifeng.com/room/";
		
		
		public function PlugGuideShowroom(id:int)
		{
			this.id = id;
			
			_itemList = new Vector.<GuideItemShowroom>;
			creatItem();
			
			_tfNextMsg.width  = MAX_W
			_tfNextMsg.height = 50;
			addChild(_tfNextMsg);
			_tfNextMsg.selectable = false;
			
			_tfTitle = new TextField();
			_tfTitle.width  = MAX_W;
			_tfTitle.height = 40;
			_tfTitle.y  = _tfNextMsg.y+_tfNextMsg.height;
			_tfTitle.selectable = false;
			this.addChild(_tfTitle);
			
			this.addChild(_layerItem);
			_layerItem.y = _tfTitle.y+_tfTitle.height+30;
			
		}
		
		
		/**参数*/
		public function set param(value:Object):void{
			_param = value;
		}
		
		/**启动*/
		public function start(callback:Function):void{
			
			_callback = callback;
			
			_tfTitle.text = "";
			
			var  sLoader2:SimpleUrlLoader = new SimpleUrlLoader(null,2);
			sLoader2.listener(getDataResult);
			
			var url:String = nextIssueUrl+LiveConfig.get.initOption.roomId+"/rec?rd="+int(Math.random() * 999);
			sLoader2.startLoad(url);
		}
		
		
		/**
		 * 获取数据结果
		 */
		private function getDataResult(data:Object):void
		{
			switch(data["type"]){
				case Event.COMPLETE :
					var content:Object = data["content"];	
					
					var resStr:String = String(content.data);
					var data:Object = com.adobe.json.JSON.decode(resStr);
					
					if(data["response"]["data"]==null){
						return;
					}
					
					data = null;
					
					initList(content["data"]);
					initTitle(content["data"]);
					break;
			}
			
		}
		
		
		/**结束  @param callback(结束回调)*/
		public function end():void{
		}
		
		/**
		 * 更新
		 */
		public function screenChange(w:int,h:int):void
		{
			this.x = (w - MAX_W)/2 ;
			this.y = (h-500)/2;
			
			_layerItem.x = (MAX_W - 290)/2;
		}
		
		
		/**
		 * 从推荐列表中剔除当前直播间 防止在自己的直播间推荐自己
		 */
		private function removeAnchorInfoByRoomdId(arr:Array):void
		{
			var len:int = arr.length>=4?4:arr.length;
			for(var i:int=0; i<len;i++)
			{
				if(String(arr[i]["roomId"]) == LiveConfig.get.initOption.roomId)
				{
					arr.splice(i,1);
					return;
				}
			}
		}
		
		
		/**
		 * 创建ITEM
		 */
		private function creatItem():void
		{
			for(var i:int=0; i<4;i++)
			{
				_itemList.push(new GuideItemShowroom());
			}
		}
		
		
		private function initList(jsonStr:String):void
		{
			
			if(_layerItem.numChildren){
				_layerItem.removeChild(_layerItem.getChildAt(0));
			}
			var data:Object = com.adobe.json.JSON.decode(jsonStr);
			
			var list:Array = data["response"]["data"]["data"];
			
			//removeAnchorInfoByRoomdId(list);
			
			var len:int = list.length>4? 4:list.length;
			if(len == 0) return;
			
			
			var item:GuideItemShowroom;
			for(var i:int = 0; i<len; i++)
			{
				item = _itemList[i];
				_layerItem.addChild(item);
				item.setData(list[i]);
				item.x = i%2 * 150;
				item.y = int(i/2) * 170;
				
			}
			
			
			
		}
		
		private function initTitle(jsonStr:String):void
		{
			var data:Object = com.adobe.json.JSON.decode(jsonStr);
			
			var str:String = data["response"]["data"]["next"];
			
			if(str.indexOf("目前暂无直播") >0){
				_tfNextMsg.htmlText = getHtml(str,20,"#FFFFFF");
			}else{
				_tfTitle.htmlText = getHtml(str,16,"#FFFFFF");
			}
			
		}
		
		
		private function getHtml(label:String,size:int,color:String):String{
			
			var html:String = "<p align='center'> <font size='"+size+"' color='"+color+"' face='微软雅黑,Microsoft YaHei,Arial'>";
			html+=label;
			html+="</font></b></p>";
			return html;
		}
		
		
		
		
		/**
		 * 全屏切换
		 */
		private function quitHandler(event:Event):void
		{
			//_callback.call(null,{type:PluginConfig.CALLBACK_TYPE_EXIT_FULL_SCREEN,data:null});
		}
		
		
		/**
		 * 设置样式
		 */
		private function setTfStyle(tf:TextField,tfm:TextFormat):void
		{
			tf.defaultTextFormat = tfm;
			tf.setTextFormat(tfm);
		}
		
		private function ioErrorHandler(event:IOErrorEvent):void
		{
			trace('io error');
		}
		
		
		public function destroy():void
		{
		}
		
		
		private var _tfTitle:TextField;
		private var _itemList:Vector.<GuideItemShowroom>;
		private var _layerItem:Sprite = new Sprite();
		
		private var _param:Object;
		//回调
		private var _callback:Function;
		
		private var _tfNextMsg:TextField = new TextField();
		
		
		
		
	}
}