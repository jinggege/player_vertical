package com.laifeng.view.video
{
    import com.laifeng.config.ListenerType;
    import com.laifeng.config.LiveConfig;
    import com.laifeng.config.ModuleKey;
    import com.laifeng.config.NoticeKey;
    import com.laifeng.config.UIKey;
    import com.laifeng.controls.DMCenter;
    import com.laifeng.controls.DMReport;
    import com.laifeng.controls.DataModule;
    import com.laifeng.controls.Notification;
    import com.laifeng.controls.UIManage;
    import com.laifeng.event.MEvent;
    import com.laifeng.interfaces.IUI;
    
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.IOErrorEvent;
    import flash.events.MouseEvent;
    import flash.events.NetStatusEvent;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    
    import lf.media.core.data.ErrorCode;
    import lf.media.core.util.Console;
    import lf.media.core.util.EnterframeTimer;
    import lf.media.core.util.EnterframeTimerVO;
    import lf.media.core.util.Util;
    import lf.media.core.video.CallbackData;
    import lf.media.core.video.CallbackType;
    import lf.media.core.video.ILfVideo;
    import lf.media.core.video.LfNomalVideo;
    
    public class VideoV extends Sprite implements IUI{
		
        public function VideoV() {
			super();
			this.mouseChildren = false;
			Notification.get.addEventListener(NoticeKey.N_COMMAND_STOP,liveStopHandler);
			Notification.get.addEventListener(NoticeKey.N_CHANGE_VOLUME,volumeChangeHandler);
			Notification.get.addEventListener(NoticeKey.N_PLAY_PAUSE,changePauseHandler);
			this.addChild(_layerVideo);
        }
        
		
		public function open():void{
			
			UIManage.get.closeUI(UIKey.UI_BACKGROUND);
			LiveConfig.liveStatus = 2;
			
			_width  = LiveConfig.get.defaultWidth;
			_height = LiveConfig.get.defaultHeight;
			
			_dmCenter                = DataModule.get.getModule(ModuleKey.DM_LIVECORE) as DMCenter;
			_reportDataModule = DataModule.get.getModule(ModuleKey.DM_REPORT) as DMReport;
			
			Notification.get.notify(new MEvent(NoticeKey.CLOSE_UI,UIKey.UI_ERROR));
			
			this._isPause = false;
			
			readPlay();
			
			EnterframeTimer.get.remove(ListenerType.TIME_NS_UPDATA);
			EnterframeTimer.get.addListener(
				new EnterframeTimerVO(ListenerType.TIME_NS_UPDATA,
					nsInfoListener,10));
			
			_skipTimer.addEventListener(TimerEvent.TIMER,skipHandler);
			_skipTimer.start();
		}
		
		
		private function readPlay():void{
			creatVideoByType();
			screenChange(_width,_height);
			this.play();
		}
		
		public function updata():void{
		
		}
		
		public function screenChange(w:int,h:int):void{
				setWH(w,h);
		}
		
		
		private function creatVideoByType():void{
			
				clearVideo();
			
				_cVideo = new LfNomalVideo(callbackByVideo);
				_cVideo.creat(null);
				
				_cVideo.netStream.bufferTime        = 3;
				_cVideo.netStream.bufferTimeMax = 10 ;
				_cVideo.netStream.inBufferSeek      = true;
				_cVideo.netStream.checkPolicyFile  = true;
				_cVideo.netStream.removeEventListener(NetStatusEvent.NET_STATUS,netStartHandler);
				_cVideo.netStream.addEventListener(NetStatusEvent.NET_STATUS,netStartHandler);
				
				_layerVideo.addChild(DisplayObject(_cVideo));
				LiveConfig.get.streamLogData.videoTime = Util.getTime;
				
		}
		
		
		private function netStartHandler(event:NetStatusEvent):void{
			callbackByVideo(new CallbackData(event.info.code,event))
		}
		
        
		private function liveStopHandler(event:MEvent):void{
			UIManage.get.closeUI(UIKey.UI_VIDEO);
			UIManage.get.closeUI(UIKey.UI_ERROR);
			UIManage.get.openUI(UIKey.UI_PLUGS);
			UIManage.get.closeUI(UIKey.UI_COUNTDOWN);
		}
		
        
        public function play():void {
			_lastNsTime = 0;
			if(_cVideo == null) return;
			
			LiveConfig.currVideoStatus = NoticeKey.TYPE_VIDEO_STATUS_PLAYING;
			UIManage.get.openUI(UIKey.UI_CONTROLBAR);
			UIManage.get.closeUI(UIKey.UI_PLUGS);
			
			_cVideo.play(_dmCenter.getStreamUrl());
			
			_seekCount = 0;
			
			_isFirstBufferFull = true;
			_pullStreamUseTime = Util.getTime;
        }
		
		
        
        private function setWH(w:Number, h:Number):void{
            _width = w;
            _height = h;
			
			if(_cVideo == null) return;
			
			var cW:int = 320;
			var cH:int = 240;
			
			if(_streamWidth > _streamHeight){
				if(w/h > _streamWidth/_streamHeight){
					cW  = h * _streamWidth/_streamHeight;
					cH = h;
				}else{
					cW  = w;
					cH = w *_streamHeight/_streamWidth;
				}
			}
			
			
			if(_streamWidth <= _streamHeight){
				cW  = h * _streamWidth/_streamHeight;
				cH = h;
			}
			
			_cVideo.setSmoothing = true;
			if(w==_streamWidth &&  h==_streamHeight){
				_cVideo.setSmoothing = false;
			}
			
			
			LiveConfig.get.streamLogData.videoWH = cW +"x"+ cH;
			_cVideo.resize(cW,cH);
			DisplayObject(_cVideo).x = (w-DisplayObject(_cVideo).width)/2;
			DisplayObject(_cVideo).y = (h - DisplayObject(_cVideo).height)/2;
			
			this.setVolume(LiveConfig.currentVolume);
        }
        
        public function close():void {
			_lastNsTime = 0;
			LiveConfig.currVideoStatus = NoticeKey.TYPE_VIDEO_STATUS_CLOSE;
			EnterframeTimer.get.remove(ListenerType.TIME_NS_UPDATA);
			EnterframeTimer.get.remove(ListenerType.TIME_ONMAC_SAFARI_BUFFER);
			clearVideo();
			
			UIManage.get.closeUI(UIKey.UI_VIDEO);
			UIManage.get.closeUI(UIKey.UI_LOADING);
			UIManage.get.closeUI(UIKey.UI_CONTROLBAR);
			this._buffEmptyDuration = -1;
			_skipTimer.stop();
			_skipTimer.removeEventListener(TimerEvent.TIMER,skipHandler);
        }
        
		
		/**暂停功能*/
        public function pause():void{
			_cVideo.volume = 0;
			_cVideo.pause();
        }
        
		
		private function callbackByVideo(data:CallbackData):void{
			Console.log("NetStatus=",data.callbackType,"  data=",data.data);
			
			switch(data.callbackType){
				case "NetStream.Play.StreamNotFound" :
					_reportDataModule.sendStreamError({msg:"StreamNotFound"});
					_reportDataModule.sendStreamFailReport({d:Util.getTime - LiveConfig.serviceUseTime});
					this.close();
					Notification.get.notify(new MEvent(NoticeKey.N_ERROR_MSG,ErrorCode.ERROR_3000));
					break;
				case "NetStream.Play.Start":
					break;
				case "NetStream.Play.Stop":
					break;
				case "NetStream.Buffer.Full":
					this._buffEmptyDuration = -1;
					if(_isFirstBufferFull){
						_reportDataModule.sendStreamSucceedReport({d:Util.getTime - LiveConfig.serviceUseTime});
						_reportDataModule.sendStreamDelay({delayTime:Util.getTime - _pullStreamUseTime});
						_isFirstBufferFull = false;
					}
					LiveConfig.get.streamLogData.addBufferFullCount();
					
					
					if(this.buffEmptyPoint != 0){
						LiveConfig.get.streamLogData.bufferEmptyTime += Util.getTime - this.buffEmptyPoint;
						this.buffEmptyPoint = 0;
					}
					
					UIManage.get.closeUI(UIKey.UI_LOADING);
					break;
				case "NetStream.Buffer.Empty":
					_buffEmptyDuration = Util.getTime;
					_cbec++;
					_lastNsTime = _cVideo.netStream.time;
					LiveConfig.get.streamLogData.addBufferEmptyCount();
					
					this.buffEmptyPoint = Util.getTime;
					UIManage.get.openUI(UIKey.UI_LOADING);
					break;
				case "NetStream.Seek.InvalidTime":
					var frame:uint = data.data.info.details;
					trace("seek=====",frame);
					_lastSeek = frame;
					
					break;
				case "NetStream.Buffer.Flush":
					UIManage.get.openUI(UIKey.UI_LOADING);
					break;
				
				case "NetStream.Play.InsufficientBW":
					//todo 客户端没有足够的带宽，无法以正常速度播放数据
					Console.log("warning:客户端没有足够的带宽，无法以正常速度播放数据");
					break;
				case "NetStream.Play.NoSupportedTrackFound":
					//todo 未检测到任何受支持的轨道（视频、音频或数据），并且不会尝试播放此文件
					Console.log("warning:未检测到任何受支持的轨道（视频、音频或数据），并且不会尝试播放此文件");
					break;
				
				case "NetStream.Play.Failed" :
					//todo 播放错误
					Console.log("warning:播放错误！");
					break;
				//-----------p2p------------------------
				case CallbackType.CT_P2P_LIB_ERR :
					/*
						_reportDataModule.sendStreamFailReport({d:Util.getTime - LiveConfig.serviceUseTime});
						_dmCenter.getLiveCoreData().isP2p = false;
						creatVideoByType();
						this.play();
					*/
					break;
				
				
				case CallbackType.CT_ONMETADATA :
						_streamWidth = data.data["width"]==null?  _streamWidth:data.data["width"];
						_streamHeight = data.data["height"]==null? _streamHeight:data.data["height"];
						LiveConfig.get.streamLogData.streamWH = ""+_streamWidth+"x"+_streamHeight;
						Console.log("metada",_streamWidth,_streamHeight);
						setWH(_width,_height);					
					break
				
				case IOErrorEvent.IO_ERROR:
					/*
						_reportDataModule.sendStreamError({msg:data["data"]});
						this.close();
						Notification.get.notify(new MEvent(NoticeKey.N_ERROR_MSG,NoticeKey.ERROR_3000));
					*/
					break
				
				default:
					
					break;
				
			}
		}
		
		
		/**音量更新*/
		private function volumeChangeHandler(event:MEvent):void{
			if(_cVideo==null) return;
			LiveConfig.currentVolume = Number(event.data);
			_lastVolume       = LiveConfig.currentVolume;
			this.setVolume(LiveConfig.currentVolume);
		}
		
		
		public function setVolume(value:Number):void{
			if(LiveConfig.get.defaultWidth<100){
				//直播台 小窗口时  屏蔽声音
				_cVideo.volume = 0;
			}else{
				_cVideo.volume = value;
			}
		}
		
		
		/**播放  暂停 切换*/
		private function changePauseHandler(event:MEvent):void{
			
			
			_cVideo.netStream.seek(_cVideo.netStream.time+1);
			_cVideo.netStream.bufferTime = 0;
			return;
			
			
			if(_cVideo == null) return;
			var status:String  =event.data as String;
			switch(status){
				case NoticeKey.TYPE_VIDEO_STATUS_PAUSE:
					_cVideo.pause();
					this._isPause = true;
					break;
				case NoticeKey.TYPE_VIDEO_STATUS_PLAYING:
					_cVideo.resume();
					this._isPause = false;
					break;
			}
		}
		
		
		private function nsInfoListener():void{
			if(_cVideo.netStream == null) return;
			
			LiveConfig.get.streamLogData.available             = LiveConfig.get.isP2p;
			LiveConfig.get.streamLogData.bufferTime         = _cVideo.netStream.bufferTime;
			LiveConfig.get.streamLogData.bufferLength      = _cVideo.netStream.bufferLength;
			LiveConfig.get.streamLogData.bytesLoaded      = _cVideo.netStream.bytesLoaded;
			LiveConfig.get.streamLogData.nsTime                = _cVideo.netStream.time;
			LiveConfig.get.streamLogData.decodedFrames = _cVideo.netStream.decodedFrames;
			LiveConfig.get.streamLogData.currFps 				 = _cVideo.netStream.currentFPS;
			
			/*
			if(_cVideo.mediaType == MediaType.VIDEO_P2P){
					try{
						LiveConfig.get.streamLogData.peerStatus         = _cVideo.netStream["getPeerStatus"]();
						LiveConfig.get.streamLogData.playStatus          = _cVideo.netStream["getPlayStatus"]();
						LiveConfig.get.streamLogData.setDelay             = _cVideo.netStream["getCloseDelayTime"]();
						LiveConfig.get.streamLogData.localconntionId = _cVideo.netStream["getLocalConnectionId"]();
						LiveConfig.get.streamLogData.lastPlayId           = _cVideo.netStream["getCurrPlayIdSwitchClarity"]();
					}catch(error:Error){
						//todo
					}
			}
			*/
			
			
			if(_cVideo.netStream.bufferLength<1.5){
				_cVideo.netStream.bufferTime = 1;
			}
			
			if(_cVideo.netStream.bufferLength>1.5){
				_cVideo.netStream.bufferTime = 2;
			}
			
			
				if(Util.getTime - _lastCvTime>=_cvLogDelay){
					LiveConfig.get.streamLogData.currBfeCount = _cbec;
					_reportDataModule.sendCVLog();
					_cbec = 0;
					_lastCvTime = Util.getTime;
					
						if(this._buffEmptyDuration != -1){
							LiveConfig.get.streamLogData.bufferEmptyTime += Util.getTime - this._buffEmptyDuration;
							
								if(Util.getTime - this._buffEmptyDuration > repullDelay){
									//buffer 空 两分钟 重新拉流
									_cVideo.play(_dmCenter.getStreamUrl());
									this._buffEmptyDuration = -1;
								}
						}
						
						
				}
				
				if(_cVideo.netStream.bufferLength > LiveConfig.get.streamLogData.bufferMaxLength){
					LiveConfig.get.streamLogData.bufferMaxLength = _cVideo.netStream.bufferLength;
				}
				
				
				if(_cVideo.netStream.bufferLength >= _cVideo.netStream.bufferTime){
					if(_cVideo.netStream.decodedFrames< _avgFrame){
						LiveConfig.get.streamLogData.lowFrameTime +=1;
					}
				}
				
				
				if(_cVideo.netStream.bufferLength > 1){
					if(UIManage.get.getUI(UIKey.UI_LOADING).uiState == UIManage.UI_STATE_OPEN){
						UIManage.get.closeUI(UIKey.UI_LOADING);
					}
				}
			
		}
		
		
		
		private var _skipCount:int = 0;
		private function skipHandler(event:TimerEvent):void{
			if(_cVideo == null) return;
			if(_cVideo.netStream==null) return;
			if( _cVideo.netStream.bufferLength>2.8){
				
				if(_cVideo.netStream.time <10) return;
				_skipCount++;
				_cVideo.netStream.seek(_cVideo.netStream.time+1);
				trace("skip = ",_skipCount);
				
			}
		}
		
		
		
		public function get level():int{
			return UIKey.UI_LEVEL_0;
		}
		
		public function set uiState(value:String):void{
			this._uiState = value;
		}
		
		public function get uiState():String{
			return this._uiState;
		}
		
		
		private function clearVideo():void{
			if(_cVideo != null){
				if(_layerVideo.contains(DisplayObject(_cVideo))){
					_layerVideo.removeChild(DisplayObject(_cVideo));
				}
				_cVideo.destroy();
			}
			
			_cVideo = null;
			
			LiveConfig.get.streamLogData.clearData();
		}
		
		
		
		public function destroy():void{
			
		}
		
		
		private var _width:Number;
		private var _height:Number;
		
		private var _lastVolume:Number = 0.5;
		
		//===========2015_1_8 整改逻辑==========================
		/**层 video*/
		private var _layerVideo:Sprite = new Sprite();
		
		private var _cVideo:ILfVideo;
		
		private var _reportDataModule:DMReport;
		/**暂停/播放状态*/
		private var _isPause:Boolean = false;
		
		private var _dmCenter:DMCenter;
		
		
		private var _attributeKey:String = "";
		private var _uiState:String;
		
		/**1000X60*/
		private var _cvLogDelay:int = 60000;
		private var _lastCvTime:Number=Util.getTime;
		/**第一次buffer full*/
		private var _isFirstBufferFull:Boolean = true;
		/**从开始拉流 到 第一次buffer full 所用时间  单位 ms*/
		private var _pullStreamUseTime:Number = 0;
		/**当前下载速度    kb/s*/
		private var _currDownSpeed:int = 0;
		/**当前buffer 是否空*/
		private var _lastNsTime:Number     = 0;
		private var _lastDecodeFrame:uint = 0;
		private var _safariBlockCount:int    = 0;
		private var _cbec:int = 0; //1分钟内buffer empty 次数
		
		private var _streamWidth:int = 320;
		private var _streamHeight:int = 240;
		/**buffer 为空持续时间*/
		private var _buffEmptyDuration:Number = -1;
		private var repullDelay:int = 30000 //重新拉流间隔   单位 ms
		private var showLoadingDelay:int = 1000; //出现loading间隔   单位 ms
		private var buffEmptyPoint:Number = 0;
		private var _avgFrame:int = 15;
		private var _buffMax:int    = 20;
		private var _lastSeek:uint  = 0;
		private var _seekCount:int = 0;
		private var _skipTimer:Timer = new Timer(2000);
		
		
		
    }
}