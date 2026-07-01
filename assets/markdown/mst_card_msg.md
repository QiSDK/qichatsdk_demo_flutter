好的，这是从图片中提取的内容，并保持了原有的表格排版：

| 字段名 | 类型 | 说明 |
| :--- | :--- | :--- |
| id | number | 主键 ID |
| questionType | number | 问题类型 (1=模糊 2=精准) |
| category | number | 归属分类 (1=充值 2=提现 3=账户 4=补单) |
| subject | string | 推送主题 (卡片标题) |
| content | string/[ ] | 推送内容: 模糊题为字符个数组, 精准题为普通字符串 |
| rightImageUrl | string | 右侧图片链接, 精准问题可用, 空字符表示无图 |
| jumpCategory | number | 跳转分类 (0=无 1=小程序 2=H5 3=原生页) |
| jumpUrl | string | 跳转链接, 模糊问题为空字符串 |
| keywords | string[ ] | 关键词数组, 用于匹配用户输入 |
| weight | number | 权重, 值越大靠前, 0表示置底 |