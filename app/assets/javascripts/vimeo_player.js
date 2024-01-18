class VimeoPlayer {
    constructor(player, host, IIM) {
        this.player = player;
        this.host = host;
        this.startTime = 0;
        this.IIM = IIM;
    }

    initializePlayer() {
        this.player.ready().then(() => {
            const videoDuration = this.player.getDuration();
            $('#item_length').val(videoDuration);
            this.IIM.getIndexSegmentsTimeline(videoDuration, this.host);
            this.handleStartTime();
        });
    }

    handleStartTime() {
        const searchParams = new URLSearchParams(window.location.search);
        if (searchParams.has('time')) {
            this.startTime = parseFloat(searchParams.get('time'));
        } else {
            const edit = $('.video_time').val();
            if (edit !== undefined && edit !== "00:00:00") {
                this.startTime = parseFloat(humanToSeconds(edit));
            }
        }

        this.playVideoWithDelay();
    }

    playVideoWithDelay() {
        setTimeout(() => {
            this.player.setCurrentTime(this.startTime);
            $('.video_time').val(secondsToHuman(this.startTime));
            this.playVideo();
        }, 1000);
    }

    playVideo() {
        let playPromise = this.player.play();

        if (playPromise) {
            playPromise.then(() => {
                this.player.setCurrentTime(this.startTime);
                this.player.play();
            }).catch(() => this.handlePlaybackError());
        }
    }

    handlePlaybackError() {
        document.addEventListener('click', () => {
            this.player.setVolume(0.4);
        });

        this.player.setVolume(0);
        setTimeout(() => this.player.play(), 1000);
    }
}
