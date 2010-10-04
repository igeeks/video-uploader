(function($) {

	$.fn.video = function(objVideo,settings) {

		var config = {
			template: $("<div>"),
			onMouseOver: "",
			onMouseOut: ""
		};

		this.updater = null;

		if (settings) $.extend(config, settings);

		init(this);
		
		this.mouseover(function(){
			if($.isFunction(config.onMouseOver)){
				config.onMouseOver.call(this, excerpt);
			}
		});
		
		this.mouseout(function(){
			if($.isFunction(config.onMouseOut)){
				config.onMouseOut.call(this, excerpt);
			}
		});

		function init(self){
			self.append(config.template.clone().children(0));
			self.attr("id","video_" + objVideo.id);
			self.addClass("video");

			self.find(".title").html(objVideo.title);
			self.find(".timestamp").html(humane_date(objVideo.created_at));

			self.find(".links a.edit").attr("href","/videos/" + objVideo.id + "/edit")
			self.find(".links a.view").attr("href","/videos/" + objVideo.id + "/")
			self.find(".links a.delete").attr("href","/videos/" + objVideo.id + "/")
			
			self.find("a.delete").click(function(event){ 
				event.preventDefault();
				if (confirm("Are you sure you want to delete this item?")){
					jQuery.post(this.href, { _method: 'delete' }, null, "script");
					self.slideUp();
				}
				return false;
			});

			refresh(self);
		}

		function refresh(self){
			self.find(".status span").html(objVideo.state.toTitleCase());
			self.find(".status").addClass(objVideo.state.toLowerCase());

			if (objVideo.state.toLowerCase() == "complete"){
				complete(self);
				self.find(".status").removeClass("transcoding");
				var img_src = "http://s3.amazonaws.com/blography/assets/" + objVideo.id + "/thumbnails/thumb_0001.png"
				self.find(".thumbnail div").append($('<img>').attr("src", img_src));
				self.find(".duration").html(duration({defaultText: "Unknown"}));
				self.find(".header img").hide();
				self.find(".duration").html(duration());
			}else if (objVideo.state.toLowerCase() == "failed"){
				fail(self);
				self.find(".status").removeClass("transcoding");
				self.find(".header img").hide();
			}else if (self.updater == null){
				beginUpdate(self);
			}
		}

		function complete(self){
			if (self.updater != null){
				self.updater.stop();
				self.updater = null;
				self.find(".wait_progress_overlay").remove();
			}
			self.find(".duration").html(duration());
			self.find(".links").removeClass("disabled");
			self.removeClass("working");
		}
		
		function fail(self){
			if (self.updater != null){
				self.updater.stop();
				self.updater = null;
				self.find(".links").addClass("disabled");
				self.find(".wait_progress_overlay").remove();
			}
			self.find(".duration").html("N/A");
			self.removeClass("working");
		}
		
		function beginUpdate(self){
			self.find(".links").addClass("disabled");
			self.addClass("working");

			var tmp_status = (objVideo.zc_status || objVideo.state).toTitleCase();
			self.waitProgress({message: tmp_status});

			self.updater = $.PeriodicalUpdater("/videos/" + objVideo.id + "/data", {
				method: 'get', 
				data: {id: objVideo.id},
				minTimeout: 1000,
				maxTimeout: 8000,
				multiplier: 2,
				type: 'text',
				maxCalls: 0,
				autoStop: 0
			}, function(data) {
				objVideo = JSON.parse(data).video;
				refresh(self);
			});
		}

		function duration(settings){
			var config = {
				defaultText: "Calculating..."
			};
			if (settings) $.extend(config, settings);

			if (objVideo.duration && objVideo.duration > 0){
				var secs = parseInt(objVideo.duration / 1000);
				var mins = parseInt(secs / 60);
				var rm_secs = parseInt(secs % 60);
				var str_secs = (rm_secs < 10) ? "0" + rm_secs : rm_secs
				return mins + ":" + str_secs;
			}else{
				return config.defaultText
			}
		}

		return this; 

	}

})(jQuery);