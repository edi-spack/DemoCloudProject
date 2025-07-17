package com.democloudproject.categories

import org.springframework.graphql.data.method.annotation.QueryMapping


@Controller
class CategoriesController {
    private val postDao: PostDao? = null

    @QueryMapping
    fun recentPosts(@Argument count: Int, @Argument offset: Int): MutableList<Post?> {
        return postDao.getRecentPosts(count, offset)
    }
}
