import { slides, slideIds } from '../../slides.js';

const platforms = ['threads', 'substack', 'x'] as const;

export function entries() {
	return slideIds.flatMap((type) => platforms.map((platform) => ({ type, platform })));
}

export function load({ params }: { params: { type: string; platform: string } }) {
	return { type: params.type, platform: params.platform, slide: slides[params.type] };
}
