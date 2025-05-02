---
layout:     post
title:      "在Jekyll文章中添加网易云音乐"
subtitle:   "Jekyll"
date:       2025-05-02
author:     "博海"
header-img: "img/1450094558.jpg"
musicId: 31445554
render_with_liquid: false
tags:
- Jekyll
---

首先，在 `_layouts/post.html` 中增加

```bash
<!-- 网易云音乐 -->
{% if page.musicId %}
  <div style="display: flex; justify-content: flex-end; width: 100%;">
    <div>
      <p>
        <iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id={{ page.musicId }}&auto=1&height=66"></iframe>
      </p>
      
      <p align="center">
        <font size="4px" face="隶书">
          <style>
            .vertical_line {
              width: 600px;
              height: 60px;
              background-color: #ffffff;
              border-left: 5px solid #ddd;
              text-align: left;
              opacity: 0.4;
            }
          </style>
          <div class="vertical_line">
            <strong>
              <font size="4" face="楷体">
                <p class="thick">
                  “听说音乐能让人愉悦”<br/>“你也来试试吧......”
                </p>
              </font>
            </strong>
          </div>
        </font>
      </p>
    </div>
  </div>
{% endif %}
```

之后在 `_posts` 文章的描述头中，增加网易云的音乐ID：

```html
musicId: 31445554
```

完整的头描述如:

```html
layout:     post
title:      "在Jekyll中添加网易云音乐"
subtitle:   "Jekyll"
date:       2025-05-02
author:     "博海"
header-img: "img/1450094558.jpg"
musicId: 31445554
tags:
- Jekyll
```

音乐ID可以从网易云的分享链接中找到,如：`https://music.163.com/#/song?id=31445554&uct2=U2FsdGVkX1/1XLNcS9w2Q4moQJB0ygL9ykrla6tFLRw=`