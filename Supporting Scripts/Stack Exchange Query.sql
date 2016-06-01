--https://data.stackexchange.com/

-- Most popular StackOverflow tags so far in 2016
SELECT   num.TagName AS Tag,
         row_number() OVER ( ORDER BY rate.Rate DESC) AS [2016Rank],
         row_number() OVER ( ORDER BY num.Num DESC) AS TotalRank,
         rate.Rate AS QuestionsIn2016,
         num.Num AS QuestionsTotal
FROM     (SELECT   count(PostId) AS Rate,
                   TagName
          FROM     Tags, PostTags, Posts
          WHERE    Tags.Id = PostTags.TagId
                   AND Posts.Id = PostId
                   AND Posts.CreationDate < SYSDATETIME()
                   AND Posts.CreationDate > '2015-01-01'
          GROUP BY TagName) AS rate
         INNER JOIN
         (SELECT   count(PostId) AS Num,
                   TagName
          FROM     Tags, PostTags, Posts
          WHERE    Tags.Id = PostTags.TagId
                   AND Posts.Id = PostId
          GROUP BY TagName
          HAVING   count(PostId) > 800) AS num
         ON rate.TagName = num.TagName
ORDER BY rate.rate DESC;