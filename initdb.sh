#! /bin/sh

## Install postgres and initdb ##

# brew install postgres
# initdb --locale=C -E UTF-8 $(brew --prefix)/var/postgres
# psql -l


## RUN THIS AFTER bad-db.sql DOWNLOADED ##

dropdb udiddit
createdb udiddit
psql -d udiddit -f bad-db.sql


# # create 5 tables
# psql -d udiddit -c """
# -- 1.1 Allow new users to register. Username has to be unique, at most 25 chars, can’t be empty
# ------ 2.1 List all users who haven’t created any post
# CREATE TABLE "users" (
#     "id" SERIAL PRIMARY KEY,
#     "name" VARCHAR(25) UNIQUE NOT NULL,
#     "latest_login_time" TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC')
# );
# ------ 2.3 Find a user by their username
# CREATE INDEX "username" ON "users" ("name");


# -- 1.2 Allow registered users to create topics. Topic name has to be unique, at most 30 chars, can’t be empty
# ------ Topic can have an optional description of at most 500 chars
# CREATE TABLE "topics" (
#     "id" SERIAL PRIMARY KEY,
#     "name" VARCHAR(30) UNIQUE NOT NULL,
#     "description" VARCHAR(500)
# );
# ------ 2.5 Find a topic by its name
# CREATE INDEX "topicname" ON "topics" ("name");


# -- 1.3 Allow users to post on existing topics. Post title must be at most 100 chars, can’t be empty
# ------ Posts must contain either a Url OR a Text, but NOT both
# ------ If a user gets deleted, their posts will remain but dissociated from the user
# ------ If a topic gets deleted, all associated posts must be automatically deleted
# ------ 2.6 List the latest 20 posts for a given topic
# ------ 2.7 List the latest 20 posts made by a given user
# CREATE TABLE "posts" (
#     "id" SERIAL PRIMARY KEY,
#     "user_id" INTEGER,
#     "topic_id" INTEGER,
#     "title" VARCHAR(100) NOT NULL,
#     "url" VARCHAR,
#     "text" VARCHAR,
#     "posted_time" TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
#     CONSTRAINT "fk_posts_users" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE SET NULL,
#     CONSTRAINT "fk_posts_topics" FOREIGN KEY ("topic_id") REFERENCES "topics" ("id") ON DELETE CASCADE,
#     CONSTRAINT "url_xor_text" CHECK (
#         ("url" IS NULL AND "text" IS NOT NULL) OR
#         ("url" IS NOT NULL AND "text" IS NULL)
#     )
# );
# -- 2.2 List all users who haven’t created any post
# ------ 2.8 Find all posts that link to a specific URL, for moderation purposes
# CREATE INDEX "posturl" ON "posts" ("url");


# -- 1.4 Allow users to comment on existing posts. Comment text can’t be empty, must allow comment descendants
# ------ If a user gets deleted, their comments will remain but dissociated from the user
# ------ If a post gets deleted, all associated comments must be automatically deleted
# ------ If a comment gets deleted, all its descendants must be automatically deleted
# ------ 2.11 List the latest 20 comments made by a given user
# CREATE TABLE "comments" (
#     "id" SERIAL PRIMARY KEY,
#     "user_id" INTEGER,
#     "post_id" INTEGER,
#     "parent_id" INTEGER,
#     "text" VARCHAR NOT NULL,
#     "commented_time" TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
#     CONSTRAINT "fk_comments_users" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE SET NULL,
#     CONSTRAINT "fk_comments_posts" FOREIGN KEY ("post_id") REFERENCES "posts" ("id") ON DELETE CASCADE,
#     CONSTRAINT "fk_parent_del_child" FOREIGN KEY ("parent_id") REFERENCES "comments" ("id") ON DELETE CASCADE
# );
# ------ 2.10 List all the direct children of a parent comment
# CREATE INDEX "direct_child" ON "comments" ("parent_id");


# -- 1.5 A user can vote once on a given post. Store the (up/down) vote as the 1 and -1 respectively
# ------ If a user gets deleted, their votes will remain but dissociated from the user
# ------ If a post gets deleted, all associated votes must be automatically deleted
# CREATE TABLE "votes" (
#     "post_id" INTEGER,
#     "user_id" INTEGER,
#     "score" INTEGER, -- down = -1, abstain = 0, up = 1
#     CONSTRAINT "pk_composite" PRIMARY KEY ("post_id" , "user_id"),
#     CONSTRAINT "fk_votes_users" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE SET NULL,
#     CONSTRAINT "fk_votes_posts" FOREIGN KEY ("post_id") REFERENCES "posts" ("id") ON DELETE CASCADE,
#     CONSTRAINT "vote_score" CHECK ( ("score" = -1) OR ("score" = 0) OR ("score" = 1) )
# );
# """

# # fill up 5 tables
# psql -d udiddit -c """
# -- 1. Fill up "users" tab
# INSERT INTO users ("name") (
#     SELECT DISTINCT username FROM bad_comments
#     UNION
#     SELECT DISTINCT username FROM bad_posts
#     UNION
#     SELECT DISTINCT regexp_split_to_table(upvotes, ',') FROM bad_posts
#     UNION
#     SELECT DISTINCT regexp_split_to_table(downvotes, ',') FROM bad_posts
# );

# -- 2. Fill up "topics" tab
# INSERT INTO topics ("name") (
#     SELECT DISTINCT topic FROM bad_posts ORDER BY 1
# );

# -- 3. Fill up "posts" tab
# INSERT INTO posts ("user_id", "topic_id", "title", "url", "text") (
#     SELECT
#         u.id,
#         t.id,
#         SUBSTRING(title, 1, 100),
#         url,
#         text_content
#     FROM
#         bad_posts AS bp
#     JOIN
#         users AS u
#         ON bp.username = u.name
#     JOIN
#         topics AS t
#         ON bp.topic = t.name
#     ORDER BY 3
# );

# -- 4. Fill up "comments" tab
# INSERT INTO comments ("user_id", "post_id", "text") (
#     SELECT
#         u.id,
#         bc.post_id,
#         bc.text_content
#     FROM
#         bad_comments AS bc
#     JOIN
#         users AS u
#         ON bc.username = u.name
#     ORDER BY 3
# );

# -- 5.1 Fill up "votes" tab from upvoting_user
# INSERT INTO votes ("post_id", "user_id", "score") (
#     SELECT
#         bp.id,
#         u.id,
#         1 AS score
#     FROM (
#         SELECT
#             id,
#             regexp_split_to_table(upvotes, ',') AS upvoting_user
#         FROM bad_posts
#     ) AS bp
#     JOIN
#         users AS u
#         ON bp.upvoting_user = u.name
#     ORDER BY 1,2
# );
# -- 5.2 Fill up "votes" tab from downvoting_user
# INSERT INTO votes ("post_id", "user_id", "score") (
#     SELECT
#         bp.id,
#         u.id,
#         -1 AS score
#     FROM (
#         SELECT
#             id,
#             regexp_split_to_table(downvotes, ',') AS downvoting_user
#         FROM bad_posts
#     ) AS bp
#     JOIN
#         users AS u
#         ON bp.downvoting_user = u.name
#     ORDER BY 1,2
# );
# """


# ## RUN THIS AFTER create 5 tables & fill up 5 tables are all EXECUTED ##

# pg_dump udiddit > final_udiddit.sql


# ## RUN THIS AFTER bad-db.sql DUMPED ##

# psql -d udiddit -f final_udiddit.sql