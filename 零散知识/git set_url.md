git remote -v
origin  https://kingmissh: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@github.com/kingmissh/ow_study.git (fetch)
origin  https://kingmissh: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@github.com/kingmissh/ow_study.git (push)

原有的api已经暴露，更换了新的api

直接使用git remote set-url origin https://github.com/kingmissh/ow_study.git，无法上传

必须使用token才行
git remote set-url origin https://kingmissh:<你的token>@github.com/kingmissh/ow_study.git