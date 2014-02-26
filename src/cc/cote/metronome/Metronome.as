package cc.cote.metronome
{
	
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	
	/**
	 * Dispatched when the metronome starts.
	 * 
	 * @eventType cc.cote.metronome.MetronomeEvent.START
	 */
	[Event(name="start", type="cc.cote.metronome.MetronomeEvent")]
	
	/**
	 * Dispatched each time the metronome ticks.
	 * 
	 * @eventType cc.cote.metronome.MetronomeEvent.TICK
	 */
	[Event(name="tick", type="cc.cote.metronome.MetronomeEvent")]
	
	/**
	 * Dispatched when the metronome stops.
	 * 
	 * @eventType cc.cote.metronome.MetronomeEvent.STOP
	 */
	[Event(name="stop", type="cc.cote.metronome.MetronomeEvent")]
	
	/**
	 * The <code>Metronome</code> class plays a beep sound (optional) and dispatches events at a 
	 * regular interval in a fashion similar to ActionScript's native <code>Timer</code> object. 
	 * However, unlike the <code>Timer</code> class, the <code>Metronome</code> class is not 
	 * affected by the player's frame rate. This makes it more precise and prevents the drifting 
	 * problem that occurs over time with a <code>Timer</code> object.
	 * 
	 * <p>At a moderate tempo, our tests show that the accuracy of the metronome is within ±0.03% 
	 * which is comparable to off-the-shelf consumer electronic metronomes and much better than 
	 * mechanical ones.</p>
	 * 
	 * <p>Using it is very simple. Simply instantiate it with the needed tempo and start it:</p>
	 * 
	 * <listing version="3.0">
	 * var metro:Metronome = new Metronome(140);
	 * metro.start();</listing>
	 * 
	 * <p>If you want to perform your own tasks when it ticks, simply listen to the 
	 * <code>MetronomeEvent.TICK</code> event:</p>
	 * 
	 * <listing version="3.0">
	 * var metro:Metronome = new Metronome(140);
	 * metro.addEventListener(MetronomeEvent.TICK, onTick);
	 * metro.start();
	 * 
	 * public function onTick(e:MetronomeEvent):void {
	 * 	trace('Tick!');
	 * }</listing>
	 * 
	 * <p><b>Using in Flash Pro</b></p>
	 * 
	 * <p>This library uses sound assets embedded with the <code>[Embed]</code> instruction. This 
	 * will work fine in FlashBuilder (and tools that use a similar compiler) but might give you 
	 * problems in Flash Pro. If you are using Flash Pro, you should simply link the 
	 * <code>Metronome.swc</code> file to avoid any issues.</p>
	 * 
	 * <p><b>Requirements</b></p>
	 * 
	 * <p>Because it uses the <code>SampleDataEvent</code> class of the Sound API, the 
	 * <code>Metronome</code> class only works in Flash Player 10+ and AIR 1.5+.</p>
	 * 
	 * @see cc.cote.metronome.MetronomeEvent
	 * @see http://cote.cc/projects/metronome
	 * @see http://github.com/cotejp/Metronome
	 */
	public class Metronome extends EventDispatcher
	{
		
		/** Version string of this release */
		public static const VERSION:String = '1.0a rev6';
		
		/** The only acceptable sound sample rate in ActionScript (in Hertz). */
		public static const SAMPLE_RATE:uint = 44100;
		
		[Embed(source='/cc/cote/metronome/sounds/Sine880Hz.mp3')] private var NormalBeep:Class;
		[Embed(source='/cc/cote/metronome/sounds/Sine1760Hz.mp3')] private var AccentedBeep:Class;
		
		private var _tempo:Number = 120;
		private var _interval:Number = 500.0;
		private var _startTime:Number = NaN;
		private var _lastTickTime:Number = NaN;
		private var _ticks:Number = 0.0;
		private var _sound:Sound = new Sound();
		private var _soundChannel:SoundChannel;
		private var _silent:Boolean = false;
		private var _base:uint = 4;
		private var _samplesBeforeTick:uint;
		private var _regularBeep:Sound;
		private var _accentedBeep:Sound;
		private var _i:uint = 0;
		private var _running:Boolean = false;
		private var _missed:uint = 0;
		private var _maxTickCount:uint = 0;
		
		/**
		 * Constructs a new <code>Metronome</code> object pre-set with at the desired tempo.
		 * 
		 * @param tempo 		The tempo to set the Metronome to (can be altered anytime with the 
		 * 						'tempo' property).
		 * @param silent		Indicates whether the Metronome should play audible beeps or stay 
		 * 						silent.
		 * @param base			Determines when to play accented beeps. Accented beeps will play 
		 * 						once in every n beats where n is the base.
		 * @param maxTickCount	The maximum number ot ticks to trigger. The default (0) means no 
		 * 						maximum.
		 */
		public function Metronome(
			tempo:uint = 120, silent:Boolean = false, base:uint = 4, maxTickCount:uint = 0
		) {
			this.tempo = tempo;
			this.silent = silent;
			this.base = base;
			_maxTickCount = maxTickCount;
			
			_regularBeep = new NormalBeep();
			_accentedBeep = new AccentedBeep();
		}
		
		/**
		 * Starts the metronome. <code>MetronomeEvent.TICK</code> will be dispatched each time the 
		 * <code>Metronome</code> ticks. Beeps will sound if the <code>silent</code> property is 
		 * <code>false</code>.
		 */
		public function start():void {
			_ticks = 0;
			_missed = 0;
			_samplesBeforeTick = Math.round(_interval / 1000 * SAMPLE_RATE);
			_sound.addEventListener(SampleDataEvent.SAMPLE_DATA, _onSampleData, false, 0, true);
			_running = true;
			_startTime = new Date().getTime();
			_tick();
		}
		
		/**
		 * Stops the metronome.
		 */
		public function stop():void {
			_running = false;
			_soundChannel.removeEventListener(Event.SOUND_COMPLETE, _tick);
			_sound.removeEventListener(SampleDataEvent.SAMPLE_DATA, _onSampleData);
			_soundChannel.stop();
			dispatchEvent( new MetronomeEvent(MetronomeEvent.STOP, _lastTickTime, _ticks));
			_samplesBeforeTick = 0;
		}
		
		/** @private */
		private function _onSampleData(e:SampleDataEvent):void {
			
			//			if (_audioSyncChannel) {
			//				// Latency in milliseconds
			//				var latency:Number = (e.position / 44100 / 1000) - _audioSyncChannel.position + _interval;
			//				if (latency > 0) _samplesBeforeTick -= Math.round(latency / 1000 * 44100);
			//				trace(latency);
			//			}
			
			// To maintain sound playback, we need to write between 2048 and 8192 samples to the 
			// SampleDataEvent's byte array. If we write less (or none), the channel fires the 
			// SOUND_COMPLETE event. If we try to write more, we get an error.
			for (_i = 0; _i < 8192; _i++) {
				if (_samplesBeforeTick <= 0) break;
				e.data.writeFloat(0);
				e.data.writeFloat(0);
				_samplesBeforeTick--;
			}
			
		}
		
		/** @private */
		private function _tick(e:Event = null):void {
			
			// If metronome has been stopped, we shouldn't continue dispatching events
			if (! _running) return;
			
			// Jot down current tick info and dispatch event (tick is dispatched all the time while
			// start is dispatched only the first time)
			_lastTickTime = new Date().getTime();
			_ticks++;
			if (_ticks == 1) {
				dispatchEvent( new MetronomeEvent(MetronomeEvent.START, _lastTickTime, 0));
			}
			dispatchEvent( new MetronomeEvent(MetronomeEvent.TICK, _lastTickTime, _ticks));
			
			// Play beep if requested
			if (! _silent) {
				if (_ticks % _base == 1 || base == 1) {
					_accentedBeep.play();
				} else {
					_regularBeep.play();
				}
			}
			
			// Check if _maxTickCount would be exceeded by scheduling another tick
			if (_ticks >= _maxTickCount && _maxTickCount != 0) {
				stop();
				return;
			}
			
			// Calculate the interval before next tick. If the interval is negative (meaning it 
			// should have been triggered already but was delayed because the host was overloaded), 
			// tick right away (in the hope of catching up). That's the best we can do.
			var delay:Number = _startTime + (_ticks * _interval) - _lastTickTime;
			if (delay <= 10) {
				_missed++;
				_tick();
				return;
			}
			
			_samplesBeforeTick = delay / 1000 * SAMPLE_RATE;
			_soundChannel = _sound.play();
			if (_soundChannel) {
				// Cannot use weak listener here (&*?%). I don't know why.
				_soundChannel.addEventListener(Event.SOUND_COMPLETE, _tick);
			} else {
				throw new IllegalOperationError(
					"No sound channels are available to use as Metronome's time reference"
				);
			}
			
		}
		
		/**
		 * The current tempo of the metronome in beats per minute. The tempo must be greater than 0 
		 * and less than 600 beats per minute.
		 * 
		 * @throws ArgumentError 	The tempo must be greater than 0 and less than 600 beats per 
		 * 							minute.
		 */
		public function get tempo():Number {
			return _tempo;
		}
		
		/** @private */
		public function set tempo(value:Number):void {
			
			if (value <= 0 || value > 600) {
				throw new ArgumentError(
					'The tempo must be greater than 0 and less than 600 beats per minute.'
				);
			}
			
			_tempo = value;
			_interval = 60 / _tempo * 1000;
		}
		
		/**
		 * The interval (in milliseconds) between ticks. Modifying this value alters the tempo just
		 * as modifying the tempo alters the interval between ticks. The interval must be at least
		 * 100 milliseconds long.
		 * 
		 * @throws ArgumentError The interval must be at least 100 milliseconds long.
		 */
		public function get interval():uint {
			return _interval;
		}
		
		/** @private */
		public function set interval(value:uint):void {
			
			if (value < 100) {
				throw new ArgumentError('The interval must be at least 100 milliseconds long.');
			}
			
			_interval = value;
			_tempo = 60 / _interval * 1000;
		}
		
		/** 
		 * The time when the metronome was last started expressed as the number of milliseconds 
		 * elapsed since midnight on January 1st, 1970, universal time.
		 */
		public function get startTime():Number {
			return _startTime;
		}
		
		/**
		 * The number of times the metronome ticked. This number is reset on start but not on stop.
		 * This means you can retrieve the number of times it ticked even after it was stopped.
		 */
		public function get ticks():Number {
			return _ticks;
		}
		
		/** Boolean indicating whether the beep sounds should be played or not. */
		public function get silent():Boolean {
			return _silent;
		}
		
		/** @private */
		public function set silent(value:Boolean):void {
			_silent = value;
		}
		
		/**
		 * The base tells the <code>Metronome</code> when to play accented beeps. The accented 
		 * beep is played once every n beats where n is the base. If you set the base to 1, all 
		 * beeps will be accented. If you set the base to 0, no beat will be accented.
		 */
		public function get base():uint {
			return _base;
		}
		
		/** @private */
		public function set base(value:uint):void {
			_base = value;
		}

		/** Indicates whether the metronome is currently running. */ 
		public function get running():Boolean {
			return _running;
		}

		/** 
		 * The number of times, since the metronome was started, that it couldn't properly schedule 
		 * a tick. This is typically caused by the processor being overloaded during one or a few 
		 * frames. If you get misses, make sure each frame's code is processed within the time it 
		 * has been allocated.
		 * 
		 * <p>For example, if you are running your application at 30 frames per second, each frame 
		 * has 33.3 milliseconds to complete its tasks. If it takes more than that, all processing 
		 * occuring after will be pushed back. In some instances (depending on frame rate and 
		 * metronome tempo), this could mean the processing of the Metronome events will be pushed 
		 * so far back that it will actually occur after a TICK should have been dispatched. If this 
		 * happens, the metronome will fire two or more TICKs back-to-back in order to stay in line 
		 * with the tempo.</p>
		 * 
		 * <p>Obviously, this is not desirable. The solution is to adjust your code so it stays
		 * within its allocated frame time (budget). You can verify that by using a tool such as 
		 * Adobe Scout.</p>
		 */
		public function get missed():uint {
			return _missed;
		}

		/**
		 * The beeping sound that plays for 'normal' beats. A 'normal' beat is one that falls on 
		 * beats not divisible by the <code>base</code> property. If you decide to use you own 
		 * sound, its duration should be shorter than the interval between two beats.
		 */
		public function get regularBeep():Sound {
			return _regularBeep;
		}
		
		/** @private */
		public function set regularBeep(value:Sound):void {
			_regularBeep = value;
		}

		/**
		 * The beeping sound that plays for 'accented' beats. An 'accented' beat is one that falls 
		 * on beats divisible by the <code>base</code> property. If you decide to use you own sound, 
		 * its duration should be shorter than the interval between two beats.
		 */
		public function get accentedBeep():Sound {
			return _accentedBeep;
		}

		/** @private */
		public function set accentedBeep(value:Sound):void {
			_accentedBeep = value;
		}

		/** The maximum number of times the Metronome should tick. A value of 0 means no maximum. */
		public function get maxTickCount():uint {
			return _maxTickCount;
		}

		/** @private */
		public function set maxTickCount(value:uint):void {
			_maxTickCount = value;
		}

	}
	
}

