
import { getServerConfiguration } from '../configuration';
import type { GetCollectionResponse } from './types/http-response';
import type { NewsPost as CmsNewsPost } from './types/news-posts';

export const getNewsPosts = async (skFetch: typeof fetch): Promise<NewsPost[]> => {
  const configuration = getServerConfiguration();

  const res = await skFetch(`${configuration.CMS_BASE_URL}api/news-posts?depth=5&preview=true`, {
    headers: {
      'Authorization': `api-keys API-Key ${configuration.CMS_API_KEY}`
    }
  })

  const responseContent = await res.json() as GetCollectionResponse<CmsNewsPost>;
  
  return responseContent.docs.map(doc => {

    return {
      id: doc.id,
      title: doc.title,
      datePublished: new Date(doc.datePublished),
      nodes: doc.content.root.children.map(node => {
        if (node.type === 'paragraph') {
          return { text: node.children[0]?.text ?? '', type: 'paragraph' } satisfies Paragraph
        }
        else if (node.type === 'block') {
          if (node.fields.blockType === 'lexical-media-section') {
            return { 
              size: node.fields.size,
              type: 'image-section',
              images: node.fields.images.map(image => ({
                source: image.image.url,
                alt: image.image.filename
              }))
            } satisfies ImageSection
          }
          else if (node.fields.blockType === 'lexical-read-more') {
            return {
              type: 'read-more'
            } satisfies ReadMore
          }
        }
        else if (node.type === 'list') {
          return {
            type: 'ordered-list',
            items: node.children.map(item => ({
              text: item.text
            }))
          } satisfies OrderedList
        }
  
        throw new Error('Could not recognize node type.')
      })
    }
  })
}

export interface NewsPost {
  id: string;
  title: string;
  datePublished: Date;
  nodes: (Paragraph | ImageSection | OrderedList | ReadMore)[]
}

interface Paragraph {
  type: 'paragraph';
  text: string;
}

interface ImageSection {
  type: 'image-section'
  size: 'normal' | 'wide' | 'fullscreen'
  images: {
    alt: string;
    source: string;
  }[]
}

interface OrderedList {
  type: 'ordered-list'
  items: {
    text: string;
  }[]
}

interface ReadMore {
  type: 'read-more'
}