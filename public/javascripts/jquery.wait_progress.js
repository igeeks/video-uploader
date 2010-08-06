(function($) {

	$.fn.waitProgress = function(settings) {
		var config = {
			cssClass: "wait_progress_overlay",
			imgSrc: "/images/progress_large.gif",
			imgHeight: 32,
			imgWidth: 32,
			message: "Loading"
		};

		if (settings) $.extend(config, settings);
		
		this.addClass("wait_progress_container")
		
		wait_image = $("<img>").attr("src",config.imgSrc);
		wait_overlay = $("<div>").addClass(config.cssClass);
		wait_overlay.append(wait_image);
		if (config.message.length > 0){
			wait_message = $("<p>").html(config.message);
			wait_overlay.append(wait_message);
		}
		this.append(wait_overlay)
		return this; 	
	}
	
})(jQuery);