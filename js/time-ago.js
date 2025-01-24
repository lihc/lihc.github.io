// time-ago.js

(function() {
    // 获取页面语言设置
    function getPageLanguage() {
        // 优先获取 html 标签的 lang 属性
        const htmlLang = document.documentElement.lang || 'en';

        // 语言映射表（可以根据需要扩展）
        const langMap = {
            'zh': 'zh-cn',
            'zh-CN': 'zh-cn',
            'zh-TW': 'zh-tw',
            'en': 'zh-cn',
            'ja': 'ja',
            'ko': 'ko'
            // 可以添加更多语言映射
        };

        return langMap[htmlLang] || htmlLang;
    }

    // 初始化时间显示
    function initTimeago() {
        // 设置语言
        const lang = getPageLanguage();
        moment.locale(lang);
        
        // 获取所有带有 datetime 属性的 time 标签
        const timeElements = document.getElementsByTagName('time');
        
        Array.from(timeElements).forEach(timeElement => {
            const datetime = timeElement.getAttribute('datetime');
            if (datetime) {
                const momentTime = moment(datetime);
                timeElement.textContent = momentTime.fromNow();
                timeElement.title = momentTime.format('YYYY-MM-DD HH:mm:ss');
            }
        });
    }

    // 页面加载完成后执行
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initTimeago);

    } else {
        initTimeago();
    }

    // const content = document.getElementById('content');
    // content.classList.remove('hide-content');
    // content.classList.add('show-content');

    // 定期更新时间显示
    // setInterval(initTimeago, 60000);
})();